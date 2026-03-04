#!/bin/bash

_set_setting_value::retrodeck() {
  # Set a value in the RetroDECK JSON config file. Only updates existing settings, does not create new ones.
  # Settings in the version, paths, or options sections are also exported to memory as global variables.
  # USAGE: _set_setting_value::retrodeck "$file" "$setting_name" "$setting_value" "$section(optional)"

  local file="$1"
  local setting_name="$2"
  local setting_value="$3"
  local section="${4:-}"

  if [[ -z "$section" ]]; then
    if ! jq -e --arg setting "$setting_name" 'has($setting)' "$file" > /dev/null 2>&1; then
      log w "Setting $setting_name not found at top level of $file, skipping"
      return 1
    fi
    jq --arg setting "$setting_name" --arg newval "$setting_value" \
      '.[$setting] = $newval' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

  elif jq -e --arg section "$section" '.presets | has($section)' "$file" > /dev/null 2>&1; then
    local parent_key
    parent_key=$(jq -r --arg section "$section" --arg setting "$setting_name" '
      .presets[$section]
      | paths(scalars)
      | select(.[-1] == $setting)
      | if length > 1 then .[-2] else $section end
    ' "$file")

    if [[ -z "$parent_key" ]]; then
      log w "Setting $setting_name not found in preset $section of $file, skipping"
      return 1
    fi

    if [[ "$section" == "$parent_key" ]]; then
      jq --arg section "$section" --arg setting "$setting_name" --arg newval "$setting_value" \
        '.presets[$section][$setting] = $newval' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    else
      jq --arg section "$section" --arg parent "$parent_key" --arg setting "$setting_name" --arg newval "$setting_value" \
        '.presets[$section][$parent][$setting] = $newval' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    fi

  else
    if ! jq -e --arg section "$section" --arg setting "$setting_name" '.[$section] | has($setting)' "$file" > /dev/null 2>&1; then
      log w "Setting $setting_name not found in section $section of $file, skipping"
      return 1
    fi
    jq --arg section "$section" --arg setting "$setting_name" --arg newval "$setting_value" \
      '.[$section][$setting] = $newval' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  fi

  # Export to memory if this is a core application setting
  if [[ -z "$section" || "$section" == "paths" || "$section" == "options" ]]; then
    log d "Exporting value of setting $setting_name as $setting_value"
    declare -g "$setting_name=$setting_value"
    export "$setting_name"
  fi
}

_get_setting_value::retrodeck() {
  # Get a value from the RetroDECK JSON config file.
  # USAGE: _get_setting_value::retrodeck "$file" "$setting_name" ["$section"]

  local file="$1"
  local setting_name="$2"
  local section="${3:-}"

  if [[ -z "$section" ]]; then
    jq -r --arg setting "$setting_name" '.[$setting] // empty' "$file"
  elif jq -e --arg section "$section" '.presets | has($section)' "$file" > /dev/null 2>&1; then
    jq -r --arg section "$section" --arg setting "$setting_name" \
      '.presets[$section] | .. | objects | select(has($setting)) | .[$setting] // empty' "$file"
  else
    jq -r --arg section "$section" --arg setting "$setting_name" \
      '.[$section][$setting] // empty' "$file"
  fi
}

_validate_for_compression::zip() {
  local file="$1"
  # zip accepts any file, validation is handled by extension/system matching
  return 0
}

_compress_game::zip() {
  local source_file="$1"
  local dest_file="$2"
  zip -jq9 "$dest_file.zip" "$source_file"
}

_prepare_component::framework() {
  # Perform preparation actions for the RetroDECK Framework.
  # USAGE: _prepare_component::framework "$action"

  local action="$1"

  if [[ "$action" == "reset" ]]; then
    log i "--------------------------------"
    log i "Resetting RetroDECK Framework"
    log i "--------------------------------"

    while IFS=$'\t' read -r setting_name setting_value; do
      [[ -z "$setting_name" ]] && continue
      [[ "$setting_name" =~ ^(rd_home_path|sdcard)$ ]] && continue

      local relative_path="${setting_value#*retrodeck/}"
      local new_value="$rd_home_path/$relative_path"

      log d "Setting: $setting_name=$new_value"

      set_setting_value "$rd_conf" "$setting_name" "$new_value" "retrodeck" "paths"

      declare -g "$setting_name=$new_value"
      export "$setting_name"

      if [[ "$setting_name" == "logs_path" ]]; then
        rm -rf "$new_value"
        dir_prep "$rd_xdg_config_logs_path" "$new_value"
        log d "Logs folder linked from $rd_xdg_config_logs_path to $new_value"
      else
        create_dir "$new_value"
      fi
    done < <(jq -r '.paths | to_entries[] | [.key, (.value | tostring)] | @tsv' "$rd_conf")

    create_dir -d "$XDG_CONFIG_HOME/retrodeck/graphics"
    rsync -rlD --delete --mkpath "/app/retrodeck/graphics/folder-iconsets/" "$XDG_CONFIG_HOME/retrodeck/graphics/folder-iconsets/"
  fi

  if [[ "$action" == "postmove" ]]; then
    log i "--------------------------------"
    log i "Post-moving RetroDECK Framework"
    log i "--------------------------------"

    while IFS=$'\t' read -r setting_name setting_value; do
      [[ -z "$setting_name" ]] && continue
      [[ "$setting_name" =~ ^(rd_home_path|sdcard)$ ]] && continue

      local new_path="$rd_home_path/${setting_value#*retrodeck/}"
      if [[ -d "$new_path" ]]; then
        set_setting_value "$rd_conf" "$setting_name" "$new_path" "retrodeck" "paths"
        declare -g "$setting_name=$new_path"
        export "$setting_name"
      fi
    done < <(jq -r '.paths | to_entries[] | [.key, (.value | tostring)] | @tsv' "$rd_conf")

    dir_prep "$rd_xdg_config_logs_path" "$logs_path"
  fi
}

handle_folder_iconsets() {
  local iconset="$1"

  if [[ ! "$iconset" == "false" ]]; then
    if [[ -d "$folder_iconsets_dir/$iconset" ]]; then
      while read -r icon; do
        local icon_relative_path="${icon#$folder_iconsets_dir/$iconset/}"
        local icon_relative_path="${icon_relative_path%.ico}"
        local icon_relative_root="${icon_relative_path%%/*}"
        local path_var_name="${icon_relative_root}_path"
        local path_name=""

        if [[ "$icon_relative_path" =~ (sync) ]]; then # If the icon is for a hidden folder, add the leading dot temporarily for searching
          icon_relative_path=".${icon_relative_path}"
        fi

        if [[ -v "$path_var_name" ]]; then
          path_name="${!path_var_name}"
          if [[ ! "$icon_relative_path" == "$icon_relative_root" ]]; then
            path_name="$path_name/${icon_relative_path#$icon_relative_root/}"
          fi
          if [[ ! -d "$path_name" ]]; then
            log w "Path for icon $icon could not be found, skipping..."
            continue
          fi
        elif [[ -d "$rd_home_path/$icon_relative_path" ]]; then
          path_name="$rd_home_path/$icon_relative_path"
          icon_relative_path="${icon_relative_path#.}" # Remove leading dot from actual icon name reference
        else
          log w "Path for icon $icon could not be found, skipping..."
          continue
        fi

        log d "Creating file $path_name/.directory"
        echo '[Desktop Entry]' > "$path_name/.directory"
        echo "Icon=$folder_iconsets_dir/$iconset/$icon_relative_path.ico" >> "$path_name/.directory"
      done < <(find "$folder_iconsets_dir/$iconset" -maxdepth 2 -type f -iname "*.ico")
      set_setting_value "$rd_conf" "iconset" "$iconset" retrodeck "options"
    else
      configurator_generic_dialog "RetroDeck Configurator - Toggle Folder Iconsets" "The chosen iconset <span foreground='$purple'><b>$iconset</b></span> could not be found in the RetroDECK assets."
      return 1
    fi
  else
    while read -r path; do
      find -L "$path" -maxdepth 2 -type f -iname '.directory' -exec rm {} \;
    done < <(jq -r 'del(.paths.downloaded_media_path, .paths.themes_path, .paths.sdcard) | .paths[]' "$rd_conf")
    set_setting_value "$rd_conf" "iconset" "false" retrodeck "options"
  fi
}

#!/bin/bash

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

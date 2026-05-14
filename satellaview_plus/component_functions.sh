#!/bin/bash

export satellaview_plus_download_path="$storage_path/satellaview_plus/"
export satellaview_plus_bsx_path="$storage_path/satellaview_plus/roms/bs-x"
export satellaview_plus_config_path="$XDG_CONFIG_HOME/satellaview_plus"
export satellaview_plus_rd_config_dir="$rd_components/satellaview_plus/rd_config"
export satellaview_plus_esde_assets_dir="$rd_components/satellaview_plus/es-de"
export satellaview_plus_config_file="$satellaview_plus_config_path/config.json"
export satellaview_plus_snes9x_config="$XDG_CONFIG_HOME/satellaview_plus/snes9x/snes9x/snes9x.conf"

_set_setting_value::satellaview_plus() {
  local file="$1"
  local name="$2"
  local value="$3"
  local tmp_file
  tmp_file="$(mktemp)"
  jq --arg name "$name" --arg value "$value" '.[$name] = $value' "$file" > "$tmp_file" && mv -f "$tmp_file" "$file"
}

_get_setting_value::satellaview_plus() {
  local file="$1" name="$2" section="${3:-}"

  if [[ -z "$section" ]]; then
    jq -r --arg name "$name" '.[$name] // empty' "$file"
  elif jq -e --arg section "$section" '.presets | has($section)' "$file" > /dev/null 2>&1; then
    jq -r --arg section "$section" --arg name "$name" \
      '.presets[$section] | .. | objects | select(has($name)) | .[$name] // empty' "$file"
  else
    local section_parts section_json
    IFS='.' read -ra section_parts <<< "$section"
    section_json=$(printf '%s\n' "${section_parts[@]}" | jq -R . | jq -sc .)
    jq -r --argjson path "$section_json" --arg name "$name" \
      'getpath($path + [$name]) // empty' "$file"
  fi
}

_set_setting_value::snes9x() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")
  local section="${4:-}"

  if [[ -n "$section" ]]; then
    section=$(sed_escape_pattern "$section")
    sed -i '\^\['"$section"'\]^,\^\^'"$name"'[[:space:]]*=^s^\^'"$name"'[[:space:]]*=.*^'"$name"' = '"$value"'^' "$file"
  else
    sed -i 's^\^'"$name"'[[:space:]]*=.*^'"$name"' = '"$value"'^' "$file"
  fi
}

_get_setting_value::snes9x() {
  local file="$1" name="$2" section="${3:-}"


  fi
}

_prepare_component::satellaview_plus() {
  local action="$1"
  shift

  local component_path="$(get_own_component_path)"

  case "$action" in

    reset)
      log i "-----------------------"
      log i "Resetting Satellaview+"
      log i "-----------------------"

      log i "Clearing BS-X satellite data directory"
      create_dir -d "$satellaview_plus_download_path"

      log i "Clearing BS-X ROM directory"
      create_dir -d "$satellaview_plus_bsx_path"

      log i "Initializing Satellaview+ Launcher configuration"
      create_dir -d "$satellaview_plus_config_path"
      cp -fv "$satellaview_plus_rd_config_dir/config.json" "$satellaview_plus_config_file"
      set_setting_value "$satellaview_plus_config_file" "DownloadLocation" "$satellaview_plus_download_path" "satellaview_plus"

      log i "Initializing Snes9x configuration for Satellaview+"
      create_dir -d "$(dirname "$satellaview_plus_snes9x_config")"
      cp -fv "$satellaview_plus_rd_config_dir/snes9x.conf" "$satellaview_plus_snes9x_config"
      set_setting_value "$satellaview_plus_snes9x_config" "SRAMDirectory" "$saves_path/satellaview_plus" "snes9x" "Files"
      set_setting_value "$satellaview_plus_snes9x_config" "SaveStateDirectory" "$states_path/satellaview_plus" "snes9x" "Files"

      log i "Creating ROMs directory and copying launchers"
      create_dir "$roms_path/satellaview_plus"
      cp -rfv "$satellaview_plus_esde_assets_dir/launchers/"* "$roms_path/satellaview_plus/"

      log i "Populating gamelist.xml for ES-DE"
      local source_gamelist="$component_path/es-de/gamelist/gamelist.xml"
      local dest_gamelist="$rd_home_path/ES-DE/gamelists/satellaview_plus/gamelist.xml"
      create_dir "$(dirname "$dest_gamelist")"
      _merge_esde_gamelist "$source_gamelist" "$dest_gamelist"

      log i "Populating ES-DE media assets"
      create_dir "$rd_home_path/ES-DE/downloaded_media/satellaview_plus"
      cp -rfv "$satellaview_plus_esde_assets_dir/downloaded_media/satellaview_plus/"* "$rd_home_path/ES-DE/downloaded_media/satellaview_plus/"
    ;;

  esac
}

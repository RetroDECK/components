#!/bin/bash

export satellaview_plus_satdata_path="$storage_path/satellaview_plus/satdata"
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

  if [[ -n "$section" ]]; then
    KEY="$name" SECTION="[$section]" awk -F'=' \
      'NR==1 { sub(/^\xEF\xBB\xBF/, "") }
       BEGIN { key=ENVIRON["KEY"]; section=ENVIRON["SECTION"] }
       $0 == section { in_section=1; next }
       /^\[/ { in_section=0 }
       in_section && $0 ~ "^" key "[[:space:]]*=" {
         gsub(/^[[:space:]]*/, "", $2)
         print $2; exit
       }' "$file"
  else
    KEY="$name" awk -F'=' \
      'NR==1 { sub(/^\xEF\xBB\xBF/, "") }
       BEGIN { key=ENVIRON["KEY"] }
       $0 ~ "^" key "[[:space:]]*=" {
         gsub(/^[[:space:]]*/, "", $2)
         print $2; exit
       }' "$file"
  fi
}


# TODO: we might repurpose this function for other components like PortMaster, so it should be moved to a more generic location

# This function merges the gamelist.xml from the component's rd_config directory with the existing gamelist.xml in the ES-DE gamelists directory
# ensuring that there are no duplicate entries based on the <path> element.
# If the destination gamelist does not exist, it simply copies the source gamelist.
_merge_esde_gamelist() {
  local source_gamelist dest_gamelist tmp_file source_abs

  source_gamelist="$1"
  dest_gamelist="$2"

  log d "_merge_esde_gamelist: source='$source_gamelist' dest='$dest_gamelist'"

  if [[ ! -f "$source_gamelist" ]]; then
    log e "_merge_esde_gamelist: source file does not exist, cannot merge or copy source: $source_gamelist"
    return 1
  fi

  mkdir -p "$(dirname "$dest_gamelist")"
  log d "_merge_esde_gamelist: ensured destination directory exists: $(dirname "$dest_gamelist")"

  if [[ ! -f "$dest_gamelist" ]]; then
    log d "_merge_esde_gamelist: destination file does not exist, copying source to destination"
    cp -f "$source_gamelist" "$dest_gamelist"
    log d "_merge_esde_gamelist: copied source to destination"
    return
  fi

  if ! command -v xmlstarlet >/dev/null 2>&1; then
    log d "_merge_esde_gamelist: xmlstarlet not available, copying source to destination"
    cp -f "$source_gamelist" "$dest_gamelist"
    log d "_merge_esde_gamelist: copied source to destination without merge"
    return
  fi

  source_abs="$(realpath "$source_gamelist")"
  tmp_file="$(mktemp)"
  log d "_merge_esde_gamelist: using temporary file '$tmp_file' and source_abs='$source_abs'"

  {
    printf '%s\n' '<?xml version="1.0"?>' '<gameList>'
    xmlstarlet sel -t -m '/gameList/*[not(self::game)]' -c . "$dest_gamelist"
    log d "_merge_esde_gamelist: extracted non-game elements from destination"
    xmlstarlet sel -t -m "/gameList/game[not(path = document(\"$source_abs\")/gameList/game/path)]" -c . "$dest_gamelist"
    log d "_merge_esde_gamelist: extracted destination game entries not present in source"
    xmlstarlet sel -t -m '/gameList/game' -c . "$source_gamelist"
    log d "_merge_esde_gamelist: extracted source game entries"
    printf '%s\n' '</gameList>'
  } > "$tmp_file"

  if xmlstarlet fo -t "$tmp_file" > "${tmp_file}.fmt"; then
    mv -f "${tmp_file}.fmt" "$dest_gamelist"
    log d "_merge_esde_gamelist: formatted merged gamelist and moved to destination"
  else
    log e "_merge_esde_gamelist: failed to format merged gamelist.xml, leaving raw temp file for inspection: $tmp_file"
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

      rm -rf "$satellaview_plus_satdata_path"
      create_dir -d "$satellaview_plus_satdata_path"

      rm -rf "$satellaview_plus_bsx_path"
      create_dir -d "$satellaview_plus_bsx_path"

      rm -rf "$satellaview_plus_config_path"
      create_dir -d "$satellaview_plus_config_path"
      cp -fv "$satellaview_plus_rd_config_dir/config.json" "$satellaview_plus_config_file"

      log i "Initializing Snes9x configuration for Satellaview+"
      create_dir -d "$(dirname "$satellaview_plus_snes9x_config")"
      cp -fv "$satellaview_plus_rd_config_dir/snes9x.conf" "$satellaview_plus_snes9x_config"
      set_setting_value "$satellaview_plus_snes9x_config" "SRAMDirectory" "$saves_path/satellaview_plus" "snes9x" "Files"
      set_setting_value "$satellaview_plus_snes9x_config" "SaveStateDirectory" "$states_path/satellaview_plus" "snes9x" "Files"

      create_dir "$roms_path/satellaview_plus"
      cp -rfv "$satellaview_plus_esde_assets_dir/launchers/"* "$roms_path/satellaview_plus/"

      local source_gamelist="$component_path/es-de/gamelist/gamelist.xml"
      local dest_gamelist="$rd_home_path/ES-DE/gamelists/satellaview_plus/gamelist.xml"
      create_dir "$(dirname "$dest_gamelist")"
      _merge_esde_gamelist "$source_gamelist" "$dest_gamelist"
    ;;

  esac
}

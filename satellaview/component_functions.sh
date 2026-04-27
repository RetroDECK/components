#!/bin/bash

export satellaview_satdata_path="$storage_path/satellaview/satdata"
export satellaview_bsx_path="$storage_path/satellaview/roms/bs-x"
export satellaview_config_path="$XDG_CONFIG_HOME/satellaview"
export satellaview_rd_config_dir="$rd_components/satellaview/rd_config"
export satellaview_config_file="$satellaview_config_path/config.json"

# TODO: we might repurpose this function for other components like PortMaster, so it should be moved to a more generic location

# This function merges the gamelist.xml from the component's rd_config directory with the existing gamelist.xml in the ES-DE gamelists directory
# ensuring that there are no duplicate entries based on the <path> element.
# If the destination gamelist does not exist, it simply copies the source gamelist.
_merge_esde_gamelist() {
  local source_gamelist dest_gamelist tmp_file source_abs

  source_gamelist="$1"
  dest_gamelist="$2"

  [[ ! -f "$source_gamelist" ]] && return 0
  mkdir -p "$(dirname "$dest_gamelist")"

  if [[ ! -f "$dest_gamelist" ]]; then
    cp -f "$source_gamelist" "$dest_gamelist"
    return
  fi

  if ! command -v xmlstarlet >/dev/null 2>&1; then
    cp -f "$source_gamelist" "$dest_gamelist"
    return
  fi

  source_abs="$(realpath "$source_gamelist")"
  tmp_file="$(mktemp)"

  {
    printf '%s\n' '<?xml version="1.0"?>' '<gameList>'
    xmlstarlet sel -t -m '/gameList/*[not(self::game)]' -c . "$dest_gamelist"
    xmlstarlet sel -t -m "/gameList/game[not(path = document(\"$source_abs\")/gameList/game/path)]" -c . "$dest_gamelist"
    xmlstarlet sel -t -m '/gameList/game' -c . "$source_gamelist"
    printf '%s\n' '</gameList>'
  } > "$tmp_file"

  xmlstarlet fo -t "$tmp_file" > "${tmp_file}.fmt" && mv -f "${tmp_file}.fmt" "$dest_gamelist" || log e "Failed to format merged gamelist.xml, check the file for issues: $dest_gamelist"
}

_prepare_component::satellaview() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "-----------------------"
      log i "Resetting Satellaview+"
      log i "-----------------------"

      rm -rf "$satellaview_satdata_path"
      create_dir -d "$satellaview_satdata_path"

      rm -rf "$satellaview_bsx_path"
      create_dir -d "$satellaview_bsx_path"

      cp -fv "$satellaview_rd_config_dir/rd_config.json" "$satellaview_config_file"
      set_setting_value "$satellaview_config_file" "DownloadLocation" "$storage_path/satellaview" "satellaview"

      cp -rfv "$component_config/es-de_launchers/"* "$rom_path/satellaview/"

      local source_gamelist="$component_config/rd_assets/es-de_gamelist/gamelist.xml"
      local dest_gamelist="$rd_home/ES-DE/gamelists/satellaview/gamelist.xml"
      _merge_esde_gamelist "$source_gamelist" "$dest_gamelist"

  esac
}

_set_setting_value::satellaview() {
  local file="$1"
  local name="$2"
  local value="$3"
  local tmp_file
  tmp_file="$(mktemp)"
  jq --arg name "$name" --arg value "$value" '.[$name] = $value' "$file" > "$tmp_file" && mv -f "$tmp_file" "$file"
}
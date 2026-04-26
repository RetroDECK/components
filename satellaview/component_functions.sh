#!/bin/bash

export satellaview_satdata_path="$storage_path/satellaview/satdata"
export satellaview_bsx_path="$storage_path/satellaview/roms/bs-x"
export satellaview_config_path="$XDG_CONFIG_HOME/satellaview"
export satellaview_rd_config_dir="$rd_components/satellaview/rd_config"
export satellaview_config_file="$satellaview_config_path/config.json"

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
      
    ;;

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
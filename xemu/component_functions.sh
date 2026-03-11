#!/bin/bash

export xemu_conf="$XDG_CONFIG_HOME/xemu/xemu.toml"

_set_setting_value::xemu() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")
  local section="${4:-}"

  local sed_cmd
  sed_cmd="s^${name} = '.*'^${name} = '${value}'^; t end;"
  sed_cmd+="s^${name} =.*^${name} = ${value}^; :end"

  if [[ -n "$section" ]]; then
    section=$(sed_escape_pattern "$section")
    sed -i '\^\['"$section"'\]^,\^\^'"$name"' =^{'"$sed_cmd"'}' "$file"
  else
    sed -i "$sed_cmd" "$file"
  fi
}

_get_setting_value::xemu() {
  local file="$1" name="$2" section="${3:-}"

  if [[ -n "$section" ]]; then
    awk -v section="[$section]" -v key="$name" \
      '$0 == section { in_section=1; next }
       /^\[/ { in_section=0 }
       in_section && index($0, key " =") == 1 {
         val = substr($0, index($0,"=")+2)
         gsub(/^'"'"'|'"'"'$/, "", val)
         print val; exit
       }' "$file"
  else
    awk -v key="$name" \
      'index($0, key " =") == 1 {
         val = substr($0, index($0,"=")+2)
         gsub(/^'"'"'|'"'"'$/, "", val)
         print val; exit
       }' "$file"
  fi
}

_prepare_component::xemu() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting Xemu"
      log i "------------------------"

      rm -rf "$XDG_CONFIG_HOME/xemu"
      rm -rf "$XDG_DATA_HOME/xemu"

      # Creating config folder in $XDG_CONFIG_HOME for consistentcy and linking back to original location where component will look
      dir_prep "$XDG_CONFIG_HOME/xemu" "$XDG_DATA_HOME/xemu/xemu"
      dir_prep "$shaders_path/xemu" "$XDG_DATA_HOME/xemu/xemu/shaders"

      cp -fv "$component_config/xemu.toml" "$xemu_conf"
      create_dir "$screenshots_path/xemu"
      set_setting_value "$xemu_conf" "screenshot_dir" "'$screenshots_path/xemu'" "xemu" "General"
      set_setting_value "$xemu_conf" "bootrom_path" "'$bios_path/mcpx_1.0.bin'" "xemu" "sys.files"
      set_setting_value "$xemu_conf" "flashrom_path" "'$bios_path/Complex.bin'" "xemu" "sys.files"
      create_dir "$saves_path/xbox/xemu"
      set_setting_value "$xemu_conf" "eeprom_path" "'$saves_path/xbox/xemu/xbox-eeprom.bin'" "xemu" "sys.files"
      set_setting_value "$xemu_conf" "hdd_path" "'$bios_path/xbox_hdd.qcow2'" "xemu" "sys.files"
    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving Xemu"
      log i "------------------------"

      dir_prep "$shaders_path/xemu" "$XDG_DATA_HOME/xemu/xemu/shaders"
      set_setting_value "$xemu_conf" "screenshot_dir" "'$screenshots_path/xemu'" "xemu" "General"
      set_setting_value "$xemu_conf" "bootrom_path" "'$bios_path/mcpx_1.0.bin'" "xemu" "sys.files"
      set_setting_value "$xemu_conf" "flashrom_path" "'$bios_path/Complex.bin'" "xemu" "sys.files"
      set_setting_value "$xemu_conf" "eeprom_path" "'$saves_path/xbox/xemu/xbox-eeprom.bin'" "xemu" "sys.files"
      set_setting_value "$xemu_conf" "hdd_path" "'$bios_path/xbox_hdd.qcow2'" "xemu" "sys.files"
    ;;

  esac
}

_post_update::xemu() {
  local previous_version="$1"

}

_post_update_legacy::xemu() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$version_being_updated" "0.10.0b"; then
    log i "0.10.0b Upgrade - Postmove: xemu - Folder Creation"

    create_dir "$screenshots_path/xemu"
    prepare_component "postmove" "xemu"
  fi
}

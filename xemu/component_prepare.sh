#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"
component_extras="/app/retrodeck/components/$component_name/rd_extras"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

  log i "------------------------"
  log i "Preparing $component_name"
  log i "------------------------"

  rm -rf "$XDG_CONFIG_HOME/xemu"
  rm -rf "$XDG_DATA_HOME/xemu"

  # Creating config folder in $XDG_CONFIG_HOME for consistentcy and linking back to original location where component will look
  dir_prep "$XDG_CONFIG_HOME/xemu" "$XDG_DATA_HOME/xemu/xemu"
  dir_prep "$shaders_path/xemu" "$XDG_DATA_HOME/xemu/xemu/shaders"

  cp -fv "$component_config/xemu.toml" "$xemu_conf"
  set_setting_value "$xemu_conf" "screenshot_dir" "'$screenshots_path'" "xemu" "General"
  set_setting_value "$xemu_conf" "bootrom_path" "'$bios_path/mcpx_1.0.bin'" "xemu" "sys.files"
  set_setting_value "$xemu_conf" "flashrom_path" "'$bios_path/Complex.bin'" "xemu" "sys.files"
  set_setting_value "$xemu_conf" "eeprom_path" "'$saves_path/xbox/xemu/xbox-eeprom.bin'" "xemu" "sys.files"
  set_setting_value "$xemu_conf" "hdd_path" "'$bios_path/xbox_hdd.qcow2'" "xemu" "sys.files"
  create_dir "$saves_path/xbox/xemu/"

  # Preparing HD dummy Image if the image is not found
  if [ ! -f "$bios_path/xbox_hdd.qcow2" ];then
    cp -f "$component_extras/xbox_hdd.qcow2" "$bios_path/xbox_hdd.qcow2"
  fi
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  dir_prep "$shaders_path/xemu" "$XDG_DATA_HOME/xemu/xemu/shaders"
  set_setting_value "$xemu_conf" "screenshot_dir" "'$screenshots_path'" "xemu" "General"
  set_setting_value "$xemu_conf" "bootrom_path" "'$bios_path/mcpx_1.0.bin'" "xemu" "sys.files"
  set_setting_value "$xemu_conf" "flashrom_path" "'$bios_path/Complex.bin'" "xemu" "sys.files"
  set_setting_value "$xemu_conf" "eeprom_path" "'$saves_path/xbox/xemu/xbox-eeprom.bin'" "xemu" "sys.files"
  set_setting_value "$xemu_conf" "hdd_path" "'$bios_path/xbox_hdd.qcow2'" "xemu" "sys.files"
fi

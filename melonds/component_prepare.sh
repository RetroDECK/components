#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

  create_dir -d "$XDG_CONFIG_HOME/melonDS/"
  cp -fv "$component_config/melonDS.toml" "$melonds_config"
  set_setting_value "$melonds_config" "BIOS9Path" "$bios_path/bios9.bin" "DS" "melonds"
  set_setting_value "$melonds_config" "BIOS7Path" "$bios_path/bios7.bin" "DS" "melonds"
  set_setting_value "$melonds_config" "FirmwarePath" "$bios_path/firmware.bin" "DS" "melonds"
  set_setting_value "$melonds_config" "SaveFilePath" "$saves_path/nds/melonds" "Instance0" "melonds"
  set_setting_value "$melonds_config" "SavestatePath" "$states_path/nds/melonds" "Instance0" "melonds"
  create_dir "$saves_path/nds/melonds"
  create_dir "$states_path/nds/melonds"
  dir_prep "$bios_path" "$XDG_CONFIG_HOME/melonDS/bios"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
    dir_prep "$bios_path" "$XDG_CONFIG_HOME/melonDS/bios"
    set_setting_value "$melonds_config" "BIOS9Path" "$bios_path/bios9.bin" "DS" "melonds"
    set_setting_value "$melonds_config" "BIOS7Path" "$bios_path/bios7.bin" "DS" "melonds"
    set_setting_value "$melonds_config" "FirmwarePath" "$bios_path/firmware.bin" "DS" "melonds"
    set_setting_value "$melonds_config" "SaveFilePath" "$saves_path/nds/melonds" "Instance0" "melonds"
    set_setting_value "$melonds_config" "SavestatePath" "$states_path/nds/melonds" "Instance0" "melonds"
fi

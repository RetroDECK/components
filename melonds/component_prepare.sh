#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Resetting $component_name"
  log i "----------------------"

  create_dir -d "$XDG_CONFIG_HOME/melonDS/"
  cp -fv "$component_config/melonDS.toml" "$melonds_config"

  create_dir "$saves_path/nds/melonds"
  create_dir "$states_path/nds/melonds"
  dir_prep "$bios_path" "$XDG_CONFIG_HOME/melonDS/bios"

  set_setting_value "$melonds_config" "BIOS9Path" "\"$bios_path/bios9.bin\"" "melonds" "DS"
  set_setting_value "$melonds_config" "BIOS7Path" "\"$bios_path/bios7.bin\"" "melonds" "DS"
  set_setting_value "$melonds_config" "FirmwarePath" "\"$bios_path/firmware.bin\"" "melonds" "DS"

  set_setting_value "$melonds_config" "NANDPath" "\"$bios_path/dsi_nand.bin\"" "melonds" "DSi"
  set_setting_value "$melonds_config" "BIOS7Path" "\"$bios_path/dsi_bios7.bin\"" "melonds" "DSi"
  set_setting_value "$melonds_config" "BIOS9Path" "\"$bios_path/dsi_bios9.bin\"" "melonds" "DSi"
  set_setting_value "$melonds_config" "FirmwarePath" "\"$bios_path/dsi_firmware.bin\"" "melonds" "DSi"

  set_setting_value "$melonds_config" "SaveFilePath" "\"$saves_path/nds/melonds\"" "melonds" "Instance0"
  set_setting_value "$melonds_config" "SavestatePath" "\"$states_path/nds/melonds\"" "melonds" "Instance0"
  set_setting_value "$melonds_config" "CheatFilePath" "\"$cheats_path/MelonDS\"" "melonds" "Instance0"

fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  log i "----------------------"
  log i "Post-moving $component_name"
  log i "----------------------"

  dir_prep "$bios_path" "$XDG_CONFIG_HOME/melonDS/bios"

  set_setting_value "$melonds_config" "BIOS9Path" "\"$bios_path/bios9.bin\"" "melonds" "DS"
  set_setting_value "$melonds_config" "BIOS7Path" "\"$bios_path/bios7.bin\"" "melonds" "DS"
  set_setting_value "$melonds_config" "FirmwarePath" "\"$bios_path/firmware.bin\"" "melonds" "DS"

  set_setting_value "$melonds_config" "NANDPath" "\"$bios_path/dsi_nand.bin\"" "melonds" "DSi"
  set_setting_value "$melonds_config" "BIOS7Path" "\"$bios_path/dsi_bios7.bin\"" "melonds" "DSi"
  set_setting_value "$melonds_config" "BIOS9Path" "\"$bios_path/dsi_bios9.bin\"" "melonds" "DSi"
  set_setting_value "$melonds_config" "FirmwarePath" "\"$bios_path/dsi_firmware.bin\"" "melonds" "DSi"

  set_setting_value "$melonds_config" "SaveFilePath" "\"$saves_path/nds/melonds\"" "melonds" "Instance0"
  set_setting_value "$melonds_config" "SavestatePath" "\"$states_path/nds/melonds\"" "melonds" "Instance0"
  set_setting_value "$melonds_config" "CheatFilePath" "\"$cheats_path/MelonDS\"" "melonds" "Instance0"
  
fi

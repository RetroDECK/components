#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

  create_dir -d "$azahar_config_path"

  cp -fT "$component_config/qt-config.ini" "$azahar_config_path/qt-config.ini"

  set_setting_value "$azahar_qtconfig" "nand_directory" "$saves_path/n3ds/azahar/nand/" "azahar"
  set_setting_value "$azahar_qtconfig" "nand_directory" "$saves_path/n3ds/azahar/sdmc/" "azahar"
  set_setting_value "$azahar_qtconfig" "Paths\gamedirs\3\path" "$roms_path/n3ds" "azahar"
  set_setting_value "$azahar_qtconfig" "Paths\screenshotPath" "$screenshots_path/n3ds/azahar" "azahar"

  create_dir "$screenshots_path/n3ds/azahar"
  create_dir "$saves_path/n3ds/azahar/nand/"
  create_dir "$saves_path/n3ds/azahar/sdmc/"
fi

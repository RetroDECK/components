#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

  create_dir "$storage_path/ps4/shadps4/installed"
  create_dir "$storage_path/ps4/shadps4/addcont"
  set_setting_value "$shadps4_config" "installDirs" "$storage_path/ps4/installed" "shadps4"
  set_setting_value "$shadps4_config" "addonInstallDir" "$storage_path/ps4/addcont" "shadps4"
  set_setting_value "$shadps4_config" "saveDataPath" "$saves_path/ps4/shadps4" "shadps4"
fi

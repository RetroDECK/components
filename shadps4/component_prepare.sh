#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Prepearing shadPS4"
  log i "----------------------"

  # Add Multiuser things and reset things

  # Shared actions
    create_dir "$rd_home_storage_path/ps4/shadps4/installed"
    create_dir "$rd_home_storage_path/ps4/shadps4/addcont"
    set_setting_value "$config/config.toml" "installDirs" "$rd_home_storage_path/ps4/installed"
    set_setting_value "$config/config.toml" "addonInstallDir" "$rd_home_storage_path/ps4/addcont"
    set_setting_value "$config/config.toml" "saveDataPath" "$rd_home_saves_path/ps4/shadps4"

fi

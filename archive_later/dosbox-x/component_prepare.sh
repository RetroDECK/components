#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"
  
  create_dir "$XDG_CONFIG_HOME/dosbox-x"
  cp -fT "$component_config/dosbox-x.conf" "$dosbox_x_config"

  # Default General Storage
  create_dir "$storage_path/dosbox-x"
  set_setting_value "$dosbox_x_config" "working directory default" "$storage_path/dosbox-x" "dosbox-x"

  # Logs path
  create_dir "$logs_path/dosbox-x"
  set_setting_value "$dosbox_x_config" "logfile" "$logs_path/dosbox-x/dosbox-x.log" "dosbox-x"

fi

#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"
  
  # Apparently vpinballx-bgfx cannot create the folder by itself
  create_dir "$XDG_CONFIG_HOME/vpinballx-bgfx/.vpinball/user/"
fi

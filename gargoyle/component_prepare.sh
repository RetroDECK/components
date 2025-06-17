#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Prepearing $component_name"
  log i "----------------------"

  if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
  
    # Add Multiuser things and reset things

    # if this section is empty the if will be invalid so we put a log message here
    log d "TODO: Implement multi-user actions for $component_name"
  
  else # Single-user actions
    create_dir "$XDG_CONFIG_HOME/gargoyle"

  fi
  # Shared actions

fi

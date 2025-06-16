#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

  if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
  # Add Multiuser things and reset things

  else # Single-user actions
  create_dir "$XDG_CONFIG_HOME/kegs"

  fi
  # Shared actions


fi

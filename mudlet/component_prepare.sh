#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Prepearing Mudlet"
  log i "----------------------"

  # Add Multiuser things and reset things

  # Shared actions
  create_dir "$XDG_CONFIG_HOME/mudlet"
  dir_prep "$XDG_CONFIG_HOME/mudlet" "/app/retrodeck/components/mudlet/portable"
  dir_prep "$rd_home_saves_path/muds/profiles" "$XDG_CONFIG_HOME/mudlet/portable/profiles"

fi

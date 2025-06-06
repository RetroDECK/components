#!/bin/bash

component_name="$(basename "$(dirname "$0")")"
config="/app/retrodeck/config/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Prepearing Mudlet"
  log i "----------------------"

  # Add Multiuser things and reset things

  # Shared actions
  create_dir "$XDG_CONFIG_HOME/mudlet"
  dir_prep "$XDG_CONFIG_HOME/mudlet" "/app/retrodeck/components/mudlet/portable"
  dir_prep "$saves_folder/muds/profiles" "$XDG_CONFIG_HOME/mudlet/profiles"

fi

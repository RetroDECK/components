#!/bin/bash

component_name="$(basename "$(dirname "$0")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Prepearing shadPS4"
  log i "----------------------"

  # Add Multiuser things and reset things

  # Shared actions

fi

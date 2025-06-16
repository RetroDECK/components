#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

  log i "------------------------"
  log i "Preparing $component_name"
  log i "------------------------"
  
    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions

    else # Single-user actions

    fi
    # Shared actions

    # Reset default preset settings

fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands

fi

# Each game has it's own config and folder structure. All data is contained within each games folder under roms/openbor/<gamedir>. IDK if there is a standard path to saves and if each game looks the same.

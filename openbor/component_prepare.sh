#!/bin/bash

component_name="$(basename "$(dirname "$0")")"
config="/app/retrodeck/config/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

  log i "------------------------"
  log i "Preparing OpenBOR"
  log i "------------------------"
  
    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions

    else # Single-user actions

    fi
    # Shared actions

    # Reset default preset settings

fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands

fi

# Each game has it's own config. All data is contained within each games folder under roms/openbor/<gamedir>.

#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Resetting $component_name"
  log i "----------------------"

  dir_prep "$roms_path/quake/ironwail/id1" "$XDG_CONFIG_HOME/ironwail/id1"
fi

if [[ "$action" == "postmove" ]]; then # Run commands that apply to both resets and moves
  log i "----------------------"
  log i "Post-moving $component_name"
  log i "----------------------"
fi

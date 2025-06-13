#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Prepearing Xenia"
  log i "----------------------"

  if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
  # Add Multiuser things and reset things

  else # Single-user actions
  create_dir "$XDG_CONFIG_HOME/xenia"
  dir_prep "$saves_folder/xbox360/content" "/app/retrodeck/components/xenia/content"
  fi
  # Shared actions

  create_dir "$XDG_CACHE_HOME/xenia"
  dir_prep "$XDG_CACHE_HOME/xenia/cache" "/app/retrodeck/components/xenia/cache"
  dir_prep "$XDG_CACHE_HOME/xenia/cache0" "/app/retrodeck/components/xenia/cache0"
  dir_prep "$XDG_CACHE_HOME/xenia/cache1" "/app/retrodeck/components/xenia/cache1"


fi

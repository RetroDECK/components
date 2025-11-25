#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

  create_dir "$XDG_CONFIG_HOME/xenia"
  dir_prep "$saves_path/xbox360/content" "/app/retrodeck/components/xenia/content"

  # Caches
  create_dir "$XDG_CACHE_HOME/xenia/cache"
  create_dir "$XDG_CACHE_HOME/xenia/cache0"
  create_dir "$XDG_CACHE_HOME/xenia/cache1"
  dir_prep "$XDG_CACHE_HOME/xenia/cache" "/app/retrodeck/components/xenia/cache"
  dir_prep "$XDG_CACHE_HOME/xenia/cache0" "/app/retrodeck/components/xenia/cache0"
  dir_prep "$XDG_CACHE_HOME/xenia/cache1" "/app/retrodeck/components/xenia/cache1"

  # Storage

  create_dir "$storage_path/xenia/storage"
  dir_prep "$storage_path/xbox360/xenia/storage" "/app/retrodeck/components/xenia/storage"
  create_dir "$storage_path/xenia/fonts"
fi

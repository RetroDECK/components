#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

    log i "----------------------"
    log i "Prepearing Vita3K"
    log i "----------------------"

    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
      log d "Figure out what Vita3k needs for multi-user"

    else # Single-user actions

      # NOTE: the component is writing in "." so it must be placed in the rw filesystem. A symlink of the binary is already placed in /app/bin/Vita3K
      rm -rf "$XDG_CONFIG_HOME/Vita3K"
      create_dir "$XDG_CONFIG_HOME/Vita3K"
      cp -fvr "$config/config.yml" "$vita3kconf" # component config
      cp -fvr "$config/ux0" "$rd_home_storage_path/psvita/Vita3K/" # User config
      set_setting_value "$vita3kconf" "pref-path" "$rd_home_storage_path/psvita/Vita3K/" "vita3k"
    fi

    # Shared actions
    dir_prep "$rd_home_saves_path/psvita/vita3k" "$rd_home_storage_path/psvita/Vita3K/ux0/user/00/savedata" # Multi-user safe?
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  dir_prep "$rd_home_saves_path/psvita/vita3k" "$rd_home_storage_path/psvita/Vita3K/ux0/user/00/savedata" # Multi-user safe?
  set_setting_value "$vita3kconf" "pref-path" "$rd_home_storage_path/psvita/Vita3K/" "vita3k"
fi


#!/bin/bash

component_name="$(basename "$(dirname "$0")")"
config="/app/retrodeck/config/$component_name/rd_config"

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
      cp -fvr "$config/ux0" "$bios_folder/Vita3K/" # User config
      set_setting_value "$vita3kconf" "pref-path" "$bios_folder/Vita3K/" "vita3k"
    fi

    # Shared actions
    dir_prep "$saves_folder/psvita/vita3k" "$bios_folder/Vita3K/ux0/user/00/savedata" # Multi-user safe?
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  dir_prep "$saves_folder/psvita/vita3k" "$bios_folder/Vita3K/ux0/user/00/savedata" # Multi-user safe?
  set_setting_value "$vita3kconf" "pref-path" "$bios_folder/Vita3K/" "vita3k"
fi


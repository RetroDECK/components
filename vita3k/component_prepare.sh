#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

  # NOTE: the component is writing in "." so it must be placed in the rw filesystem. A symlink of the binary is already placed in /app/bin/Vita3K
  rm -rf "$XDG_CONFIG_HOME/Vita3K"
  create_dir "$XDG_CONFIG_HOME/Vita3K"
  cp -fvr "$component_config/config.yml" "$vita3k_config" # component config
  cp -fvr "$component_config/ux0" "$storage_path/psvita/Vita3K/" # User config
  set_setting_value "$vita3k_config" "pref-path" "$storage_path/psvita/Vita3K/" "vita3k"
  dir_prep "$saves_path/psvita/vita3k" "$storage_path/psvita/Vita3K/ux0/user/00/savedata" # Multi-user safe?
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  dir_prep "$saves_path/psvita/vita3k" "$storage_path/psvita/Vita3K/ux0/user/00/savedata" # Multi-user safe?
  set_setting_value "$vita3k_config" "pref-path" "$storage_path/psvita/Vita3K/" "vita3k"
fi

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
  cp -fv "$component_config/config.yml" "$vita3k_config" # component config
  create_dir "$storage_path/Vita3K/"
  cp -frv "$component_config/ux0" "$storage_path/Vita3K/" # User config
  set_setting_value "$vita3k_config" "pref-path" "$storage_path/Vita3K/" "vita3k"
  dir_prep "$saves_path/psvita/vita3k" "$storage_path/Vita3K/ux0/user/00/savedata" # Multi-user safe?
  dir_prep "$texture_packs_path/Vita3K/import" "$storage_path/Vita3K/ux0/textures/import" # Textures 
  dir_prep "$storage_path/Vita3K/lang"  "$XDG_DATA_HOME/Vita3K/lang"
  dir_prep "$storage_path/Vita3K/patch"  "$XDG_DATA_HOME/Vita3K/patch"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  dir_prep "$saves_path/psvita/vita3k" "$storage_path/Vita3K/ux0/user/00/savedata" # Multi-user safe?
  dir_prep "$texture_packs_path/Vita3K/import" "$storage_path/Vita3K/ux0/textures/import" # Textures 
  dir_prep "$storage_path/Vita3K/lang"  "$XDG_DATA_HOME/Vita3K/lang"
  dir_prep "$storage_path/Vita3K/patch"  "$XDG_DATA_HOME/Vita3K/patch"
  set_setting_value "$vita3k_config" "pref-path" "$storage_path/psvita/Vita3K/" "vita3k"
fi

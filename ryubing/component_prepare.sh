#!/bin/bash

# Warning Xargons work with light edits, we need to redo several aspects. Variables should be defined in component_functions.sh //Laz

# NOTE: for technical reasons the system folder of Ryujinx IS NOT a symlink of the bios/switch/keys as not only the keys are located there

# When RetroDECK starts there is a "manage_ryujinx_keys" function that symlinks the keys only in Rryujinx/system.

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

  log i "------------------------"
  log i "Preparing $component_name"
  log i "------------------------"
  
  # removing config directory to wipe legacy files
  log d "Removing \"$XDG_CONFIG_HOME/ryubing\""
  rm -rf "$XDG_CONFIG_HOME/ryubing"
  create_dir "$XDG_CONFIG_HOME/ryubing/system"
  cp -fv "$component_config/Config.json" "$ryubing_config"
  cp -fvr "$component_config/profiles/controller/"* "$ryubing_profiles_path/"
  log d "Replacing placeholders in \"$ryubing_config\""
  sed -i 's#RETRODECKHOMEDIR#'"$rd_home_path"'#g' "$ryubing_config"
  create_dir "$logs_path/switch/ryubing"
  create_dir "$mods_path/switch/ryubing"
  create_dir "$screenshots_path/switch/ryubing"
fi

# if [[ "$action" == "reset" ]] || [[ "$action" == "postmove" ]]; then # Run commands that apply to both resets and moves
#   dir_prep "$bios_path/switch/keys" "$XDG_CONFIG_HOME/ryubing/system"
# fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
    log d "Replacing placeholders in \"$ryubing_config\""
    sed -i 's#RETRODECKHOMEDIR#'"$rd_home_path"'#g' "$ryubing_config" # This is an unfortunate one-off because set_setting_value does not currently support JSON
fi

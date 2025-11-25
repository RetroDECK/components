#!/bin/bash

# NOTE: Ryubing config folder is still called Ryujinx, not ryubing
# However the RetroDECK saves folder is ryubing to avoid confusion with older Ryujinx installs, so the users can move their saves easily

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

  log i "------------------------"
  log i "Preparing $component_name"
  log i "------------------------"
  
  # removing config directory to wipe legacy files
  log d "Removing \"$XDG_CONFIG_HOME/Ryujinx\""
  rm -rf "$XDG_CONFIG_HOME/Ryujinx"
  create_dir "$XDG_CONFIG_HOME/Ryujinx/system"
  create_dir "$ryubing_profiles_path"
  cp -fv "$component_config/Config.json" "$ryubing_config"
  cp -fvr "$component_config/profiles/controller/"* "$ryubing_profiles_path/"
  log d "Replacing placeholders in \"$ryubing_config\""
  sed -i 's#RETRODECKHOMEDIR#'"$rd_home_path"'#g' "$ryubing_config"
  sed -i 's#RETRODECKSTORAGEDIR#'"$storage_path"'#g' "$ryubing_config"
  sed -i 's#RETRODECKROMSDIR#'"$roms_path"'#g' "$ryubing_config"
  create_dir "$logs_path/switch/Ryujinx"
  create_dir "$mods_path/switch/Ryujinx"
  create_dir "$screenshots_path/switch/Ryujinx"

  dir_prep "$bios_path/switch/keys" "$XDG_CONFIG_HOME/Ryujinx/system"
  dir_prep "$bios_path/switch/firmware" "$XDG_CONFIG_HOME/Ryujinx/bis/system/Contents"
  dir_prep "$saves_path/switch/ryubing" "$XDG_CONFIG_HOME/Ryujinx/bis/system/save"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
    log d "Replacing placeholders in \"$ryubing_config\""
    # This is an unfortunate one-off because set_setting_value does not currently support JSON
    sed -i 's#RETRODECKHOMEDIR#'"$rd_home_path"'#g' "$ryubing_config"
    sed -i 's#RETRODECKSTORAGEDIR#'"$storage_path"'#g' "$ryubing_config"
    sed -i 's#RETRODECKROMSDIR#'"$roms_path"'#g' "$ryubing_config"
fi

#!/bin/bash

# Warning Xargons work with light edits, we need to redo several aspects. Variables should be defined in component_functions.sh //Laz

# NOTE: for technical reasons the system folder of Ryujinx IS NOT a symlink of the bios/switch/keys as not only the keys are located there

# When RetroDECK starts there is a "manage_ryujinx_keys" function that symlinks the keys only in Rryujinx/system.

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/config/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

    log i "------------------------"
    log i "Preparing $component_name"
    log i "------------------------"

    if [[ $multi_user_mode == "true" ]]; then
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/ryubing"
        #create_dir "$multi_user_data_folder/$SteamAppUser/config/ryubing/system"
        cp -fv "$config/ryubing/"* "$multi_user_data_folder/$SteamAppUser/config/ryubing"
        sed -i '#RETRODECKHOMEDIR#'"$rd_home_path"'#g' "$multi_user_data_folder/$SteamAppUser/config/ryubing/Config.json"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/ryubing" "$XDG_CONFIG_HOME/ryubing"
    else
        # removing config directory to wipe legacy files
        log d "Removing \"$XDG_CONFIG_HOME/ryubing\""
        rm -rf "$XDG_CONFIG_HOME/ryubing"
        create_dir "$XDG_CONFIG_HOME/ryubing/system"
        cp -fv "$config/ryubing/Config.json" "$ryubing_config"
        cp -fvr "$config/ryubing/profiles/controller" "$XDG_CONFIG_HOME/$ryubing_profiles_path"
        log d "Replacing placeholders in \"$ryubing_config\""
        sed -i 's#RETRODECKHOMEDIR#'"$rd_home_path"'#g' "$ryubing_config"
        create_dir "$rd_internal_logs_path/switch/ryubing"
        create_dir "$rd_home_mods_path/switch/ryubing"
        create_dir "$rd_home_screenshots_path/switch/ryubing"
    fi
fi

# if [[ "$action" == "reset" ]] || [[ "$action" == "postmove" ]]; then # Run commands that apply to both resets and moves
#   dir_prep "$rd_home_bios_path/switch/keys" "$XDG_CONFIG_HOME/ryubing/system"
# fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
    log d "Replacing placeholders in \"$ryubing_config\""
    sed -i 's#RETRODECKHOMEDIR#'"$rd_home_path"'#g' "$ryubing_config" # This is an unfortunate one-off because set_setting_value does not currently support JSON
fi

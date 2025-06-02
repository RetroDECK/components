#!/bin/bash

if [[ "$component" =~ ^(ryujinx|all)$ ]]; then
    component_found="true"
    # NOTE: for techincal reasons the system folder of Ryujinx IS NOT a sumlink of the bios/switch/keys as not only the keys are located there
    # When RetroDECK starts there is a "manage_ryujinx_keys" function that symlinks the keys only in Rryujinx/system.
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
    log i "------------------------"
    log i "Prepearing RYUJINX"
    log i "------------------------"
    if [[ $multi_user_mode == "true" ]]; then
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/Ryujinx"
        #create_dir "$multi_user_data_folder/$SteamAppUser/config/Ryujinx/system"
        cp -fv "$config/ryujinx/"* "$multi_user_data_folder/$SteamAppUser/config/Ryujinx"
        sed -i 's#RETRODECKHOMEDIR#'"$rdhome"'#g' "$multi_user_data_folder/$SteamAppUser/config/Ryujinx/Config.json"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/Ryujinx" "$XDG_CONFIG_HOME/Ryujinx"
    else
        # removing config directory to wipe legacy files
        log d "Removing \"$XDG_CONFIG_HOME/Ryujinx\""
        rm -rf "$XDG_CONFIG_HOME/Ryujinx"
        create_dir "$XDG_CONFIG_HOME/Ryujinx/system"
        cp -fv "$config/ryujinx/Config.json" "$ryujinxconf"
        cp -fvr "$config/ryujinx/profiles" "$XDG_CONFIG_HOME/Ryujinx/"
        log d "Replacing placeholders in \"$ryujinxconf\""
        sed -i 's#RETRODECKHOMEDIR#'"$rdhome"'#g' "$ryujinxconf"
        create_dir "$logs_folder/ryujinx"
        create_dir "$mods_folder/ryujinx"
        create_dir "$screenshots_folder/ryujinx"
    fi
    fi
    # if [[ "$action" == "reset" ]] || [[ "$action" == "postmove" ]]; then # Run commands that apply to both resets and moves
    #   dir_prep "$bios_folder/switch/keys" "$XDG_CONFIG_HOME/Ryujinx/system"
    # fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
    log d "Replacing placeholders in \"$ryujinxconf\""
    sed -i 's#RETRODECKHOMEDIR#'"$rdhome"'#g' "$ryujinxconf" # This is an unfortunate one-off because set_setting_value does not currently support JSON
    fi
fi
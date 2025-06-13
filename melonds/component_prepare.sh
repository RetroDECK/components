#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

    log i "----------------------"
    log i "Prepearing melonDS"
    log i "----------------------"

    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        create_dir -d "$multi_user_data_folder/$SteamAppUser/config/melonDS/"
        cp -fvr "$config/melonds/melonDS.ini" "$multi_user_data_folder/$SteamAppUser/config/melonDS/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "BIOS9Path" "$bios_folder/bios9.bin" "melonds"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "BIOS7Path" "$bios_folder/bios7.bin" "melonds"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "FirmwarePath" "$bios_folder/firmware.bin" "melonds"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "SaveFilePath" "$saves_folder/nds/melonds" "melonds"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "SavestatePath" "$states_folder/nds/melonds" "melonds"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/melonDS" "$XDG_CONFIG_HOME/melonDS"

    else # Single-user actions
    
        create_dir -d "$XDG_CONFIG_HOME/melonDS/"
        cp -fvr "$config/melonds/melonDS.ini" "$XDG_CONFIG_HOME/melonDS/"
        set_setting_value "$melondsconf" "BIOS9Path" "$bios_folder/bios9.bin" "melonds"
        set_setting_value "$melondsconf" "BIOS7Path" "$bios_folder/bios7.bin" "melonds"
        set_setting_value "$melondsconf" "FirmwarePath" "$bios_folder/firmware.bin" "melonds"
        set_setting_value "$melondsconf" "SaveFilePath" "$saves_folder/nds/melonds" "melonds"
        set_setting_value "$melondsconf" "SavestatePath" "$states_folder/nds/melonds" "melonds"
    fi

    # Shared actions
    create_dir "$saves_folder/nds/melonds"
    create_dir "$states_folder/nds/melonds"
    dir_prep "$bios_folder" "$XDG_CONFIG_HOME/melonDS/bios"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
    dir_prep "$bios_folder" "$XDG_CONFIG_HOME/melonDS/bios"
    set_setting_value "$melondsconf" "BIOS9Path" "$bios_folder/bios9.bin" "melonds"
    set_setting_value "$melondsconf" "BIOS7Path" "$bios_folder/bios7.bin" "melonds"
    set_setting_value "$melondsconf" "FirmwarePath" "$bios_folder/firmware.bin" "melonds"
    set_setting_value "$melondsconf" "SaveFilePath" "$saves_folder/nds/melonds" "melonds"
    set_setting_value "$melondsconf" "SavestatePath" "$states_folder/nds/melonds" "melonds"
fi

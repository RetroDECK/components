#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

    log i "----------------------"
    log i "Preparing $component_name"
    log i "----------------------"

    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        create_dir -d "$multi_user_data_folder/$SteamAppUser/config/melonDS/"
        cp -fvr "$config/melonds/melonDS.ini" "$multi_user_data_folder/$SteamAppUser/config/melonDS/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "BIOS9Path" "$rd_home_bios_path/bios9.bin" "melonds"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "BIOS7Path" "$rd_home_bios_path/bios7.bin" "melonds"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "FirmwarePath" "$rd_home_bios_path/firmware.bin" "melonds"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "SaveFilePath" "$rd_home_saves_path/nds/melonds" "melonds"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "SavestatePath" "$rd_home_states_path/nds/melonds" "melonds"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/melonDS" "$XDG_CONFIG_HOME/melonDS"

    else # Single-user actions
    
        create_dir -d "$XDG_CONFIG_HOME/melonDS/"
        cp -fvr "$config/melonds/melonDS.ini" "$XDG_CONFIG_HOME/melonDS/"
        set_setting_value "$melonds_config_melonDS" "BIOS9Path" "$rd_home_bios_path/bios9.bin" "melonds"
        set_setting_value "$melonds_config_melonDS" "BIOS7Path" "$rd_home_bios_path/bios7.bin" "melonds"
        set_setting_value "$melonds_config_melonDS" "FirmwarePath" "$rd_home_bios_path/firmware.bin" "melonds"
        set_setting_value "$melonds_config_melonDS" "SaveFilePath" "$rd_home_saves_path/nds/melonds" "melonds"
        set_setting_value "$melonds_config_melonDS" "SavestatePath" "$rd_home_states_path/nds/melonds" "melonds"
    fi

    # Shared actions
    create_dir "$rd_home_saves_path/nds/melonds"
    create_dir "$rd_home_states_path/nds/melonds"
    dir_prep "$rd_home_bios_path" "$XDG_CONFIG_HOME/melonDS/bios"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
    dir_prep "$rd_home_bios_path" "$XDG_CONFIG_HOME/melonDS/bios"
    set_setting_value "$melonds_config_melonDS" "BIOS9Path" "$rd_home_bios_path/bios9.bin" "melonds"
    set_setting_value "$melonds_config_melonDS" "BIOS7Path" "$rd_home_bios_path/bios7.bin" "melonds"
    set_setting_value "$melonds_config_melonDS" "FirmwarePath" "$rd_home_bios_path/firmware.bin" "melonds"
    set_setting_value "$melonds_config_melonDS" "SaveFilePath" "$rd_home_saves_path/nds/melonds" "melonds"
    set_setting_value "$melonds_config_melonDS" "SavestatePath" "$rd_home_states_path/nds/melonds" "melonds"
fi

#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

    log i "----------------------"
    log i "Prepearing Primehack"
    log i "----------------------"

    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        create_dir -d "$multi_user_data_folder/$SteamAppUser/config/primehack"
        cp -fvr "$config/primehack/config/"* "$multi_user_data_folder/$SteamAppUser/config/primehack/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/primehack/Dolphin.ini" "ISOPath0" "$rd_home_roms_path/wii" "primehack" "General"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/primehack/Dolphin.ini" "ISOPath1" "$rd_home_roms_path/gc" "primehack" "General"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/primehack" "$XDG_CONFIG_HOME/primehack"

    else # Single-user actions

        create_dir -d "$XDG_CONFIG_HOME/primehack/"
        cp -fvr "$config/primehack/config/"* "$XDG_CONFIG_HOME/primehack/"
        set_setting_value "$primehackconf" "ISOPath0" "$rd_home_roms_path/wii" "primehack" "General"
        set_setting_value "$primehackconf" "ISOPath1" "$rd_home_roms_path/gc" "primehack" "General"
    fi

    # Shared actions
    dir_prep "$rd_home_saves_path/gc/primehack/EU" "$XDG_DATA_HOME/primehack/GC/EUR"
    dir_prep "$rd_home_saves_path/gc/primehack/US" "$XDG_DATA_HOME/primehack/GC/USA"
    dir_prep "$rd_home_saves_path/gc/primehack/JP" "$XDG_DATA_HOME/primehack/GC/JAP"
    dir_prep "$rd_home_screenshots_path" "$XDG_DATA_HOME/primehack/ScreenShots"
    dir_prep "$rd_home_states_path/primehack" "$XDG_DATA_HOME/primehack/StateSaves"
    create_dir "$XDG_DATA_HOME/primehack/Wii/"
    dir_prep "$rd_home_saves_path/wii/primehack" "$XDG_DATA_HOME/primehack/Wii"
    dir_prep "$rd_home_mods_path/Primehack" "$XDG_DATA_HOME/primehack/Load/GraphicMods"
    dir_prep "$rd_home_texture_packs_path/Primehack" "$XDG_DATA_HOME/primehack/Load/Textures"
    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        cp -fvr "$config/primehack/data/"* "$multi_user_data_folder/$SteamAppUser/data/primehack/" # this must be done after the dirs are prepared as it copying some "mods"
    fi

    # Reset default preset settings
    set_setting_value "$rd_conf" "primehack" "$(get_setting_value "$rd_defaults" "primehack" "retrodeck" "ask_to_exit")" "retrodeck" "ask_to_exit"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
    dir_prep "$rd_home_saves_path/gc/primehack/EU" "$XDG_DATA_HOME/primehack/GC/EUR"
    dir_prep "$rd_home_saves_path/gc/primehack/US" "$XDG_DATA_HOME/primehack/GC/USA"
    dir_prep "$rd_home_saves_path/gc/primehack/JP" "$XDG_DATA_HOME/primehack/GC/JAP"
    dir_prep "$rd_home_screenshots_path" "$XDG_DATA_HOME/primehack/ScreenShots"
    dir_prep "$rd_home_states_path/primehack" "$XDG_DATA_HOME/primehack/StateSaves"
    dir_prep "$rd_home_saves_path/wii/primehack" "$XDG_DATA_HOME/primehack/Wii/"
    dir_prep "$rd_home_mods_path/Primehack" "$XDG_DATA_HOME/primehack/Load/GraphicMods"
    dir_prep "$rd_home_texture_packs_path/Primehack" "$XDG_DATA_HOME/primehack/Load/Textures"
    set_setting_value "$primehackconf" "ISOPath0" "$rd_home_roms_path/gc" "primehack" "General"
fi

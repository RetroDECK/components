#!/bin/bash

# TODO: adapt me to the NEO project (maybe?)

component="$(basename "$(dirname "$0")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ $(get_setting_value "$rd_conf" "akai_ponzu" "retrodeck" "options") == "true" ]]; then
    if [[ "$component" =~ ^(citra|citra-emu|all)$ ]]; then
    component_found="true"
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
        log i "------------------------"
        log i "Prepearing CITRA"
        log i "------------------------"
        if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        create_dir -d "$multi_user_data_folder/$SteamAppUser/config/citra-emu"
        cp -fv "$config/citra/qt-config.ini" "$multi_user_data_folder/$SteamAppUser/config/citra-emu/qt-config.ini"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/citra-emu/qt-config.ini" "nand_directory" "$rd_home_saves_path/n3ds/citra/nand/" "citra" "Data%20Storage"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/citra-emu/qt-config.ini" "sdmc_directory" "$rd_home_saves_path/n3ds/citra/sdmc/" "citra" "Data%20Storage"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/citra-emu/qt-config.ini" "Paths\gamedirs\3\path" "$rd_home_roms_path/n3ds" "citra" "UI"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/citra-emu/qt-config.ini" "Paths\screenshotPath" "$rd_home_screenshots_path" "citra" "UI"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/citra-emu" "$XDG_CONFIG_HOME/citra-emu"
        else # Single-user actions
        create_dir -d "$XDG_CONFIG_HOME/citra-emu/"
        cp -f "$config/citra/qt-config.ini" "$XDG_CONFIG_HOME/citra-emu/qt-config.ini"
        set_setting_value "$citraconf" "nand_directory" "$rd_home_saves_path/n3ds/citra/nand/" "citra" "Data%20Storage"
        set_setting_value "$citraconf" "sdmc_directory" "$rd_home_saves_path/n3ds/citra/sdmc/" "citra" "Data%20Storage"
        set_setting_value "$citraconf" "Paths\gamedirs\3\path" "$rd_home_roms_path/n3ds" "citra" "UI"
        set_setting_value "$citraconf" "Paths\screenshotPath" "$rd_home_screenshots_path" "citra" "UI"
        fi
        # Shared actions
        create_dir "$rd_home_saves_path/n3ds/citra/nand/"
        create_dir "$rd_home_saves_path/n3ds/citra/sdmc/"
        dir_prep "$rd_home_bios_path/citra/sysdata" "$XDG_DATA_HOME/citra-emu/sysdata"
        dir_prep "$rd_internal_logs_path/citra" "$XDG_DATA_HOME/citra-emu/log"
        dir_prep "$mods_folder/Citra" "$XDG_DATA_HOME/citra-emu/load/mods"
        dir_prep "$rd_home_texture_packs_path/Citra" "$XDG_DATA_HOME/citra-emu/load/textures"

        # Reset default preset settings
        set_setting_value "$rd_conf" "citra" "$(get_setting_value "$rd_defaults" "citra" "retrodeck" "abxy_button_swap")" "retrodeck" "abxy_button_swap"
        set_setting_value "$rd_conf" "citra" "$(get_setting_value "$rd_defaults" "citra" "retrodeck" "ask_to_exit")" "retrodeck" "ask_to_exit"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
        dir_prep "$rd_home_bios_path/citra/sysdata" "$XDG_DATA_HOME/citra-emu/sysdata"
        dir_prep "$rd_home_path/logs/citra" "$XDG_DATA_HOME/citra-emu/log"
        dir_prep "$mods_folder/Citra" "$XDG_DATA_HOME/citra-emu/load/mods"
        dir_prep "$rd_home_texture_packs_path/Citra" "$XDG_DATA_HOME/citra-emu/load/textures"
        set_setting_value "$citraconf" "nand_directory" "$rd_home_saves_path/n3ds/citra/nand/" "citra" "Data%20Storage"
        set_setting_value "$citraconf" "sdmc_directory" "$rd_home_saves_path/n3ds/citra/sdmc/" "citra" "Data%20Storage"
        set_setting_value "$citraconf" "Paths\gamedirs\3\path" "$rd_home_roms_path/n3ds" "citra" "UI"
        set_setting_value "$citraconf" "Paths\screenshotPath" "$rd_home_screenshots_path" "citra" "UI"
    fi
    fi
fi

if [[ $(get_setting_value "$rd_conf" "kiroi_ponzu" "retrodeck" "options") == "true" ]]; then
    if [[ "$component" =~ ^(yuzu|all)$ ]]; then
    component_found="true"
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
        log i "----------------------"
        log i "Prepearing YUZU"
        log i "----------------------"
        if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        create_dir -d "$multi_user_data_folder/$SteamAppUser/config/yuzu"
        cp -fvr "$config/yuzu/"* "$multi_user_data_folder/$SteamAppUser/config/yuzu/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/yuzu/qt-config.ini" "nand_directory" "$rd_home_saves_path/switch/yuzu/nand" "yuzu" "Data%20Storage"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/yuzu/qt-config.ini" "sdmc_directory" "$rd_home_saves_path/switch/yuzu/sdmc" "yuzu" "Data%20Storage"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/yuzu/qt-config.ini" "Paths\gamedirs\4\path" "$rd_home_roms_path/switch" "yuzu" "UI"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/yuzu/qt-config.ini" "Screenshots\screenshot_path" "$rd_home_screenshots_path" "yuzu" "UI"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/yuzu" "$XDG_CONFIG_HOME/yuzu"
        else # Single-user actions
        create_dir -d "$XDG_CONFIG_HOME/yuzu/"
        cp -fvr "$config/yuzu/"* "$XDG_CONFIG_HOME/yuzu/"
        set_setting_value "$yuzuconf" "nand_directory" "$rd_home_saves_path/switch/yuzu/nand" "yuzu" "Data%20Storage"
        set_setting_value "$yuzuconf" "sdmc_directory" "$rd_home_saves_path/switch/yuzu/sdmc" "yuzu" "Data%20Storage"
        set_setting_value "$yuzuconf" "Paths\gamedirs\4\path" "$rd_home_roms_path/switch" "yuzu" "UI"
        set_setting_value "$yuzuconf" "Screenshots\screenshot_path" "$rd_home_screenshots_path" "yuzu" "UI"
        fi
        # Shared actions
        dir_prep "$rd_home_saves_path/switch/yuzu/nand" "$XDG_DATA_HOME/yuzu/nand"
        dir_prep "$rd_home_saves_path/switch/yuzu/sdmc" "$XDG_DATA_HOME/yuzu/sdmc"
        dir_prep "$rd_home_bios_path/switch/keys" "$XDG_DATA_HOME/yuzu/keys"
        dir_prep "$rd_home_bios_path/switch/firmware" "$XDG_DATA_HOME/yuzu/nand/system/Contents/registered"
        dir_prep "$rd_internal_logs_path/yuzu" "$XDG_DATA_HOME/yuzu/log"
        dir_prep "$rd_home_screenshots_path" "$XDG_DATA_HOME/yuzu/screenshots"
        dir_prep "$mods_folder/Yuzu" "$XDG_DATA_HOME/yuzu/load"
        # removing dead symlinks as they were present in a past version
        if [ -d "$rd_home_bios_path/switch" ]; then
        find "$rd_home_bios_path/switch" -xtype l -exec rm {} \;
        fi

        # Reset default preset settings
        set_setting_value "$rd_conf" "yuzu" "$(get_setting_value "$rd_defaults" "yuzu" "retrodeck" "abxy_button_swap")" "retrodeck" "abxy_button_swap"
        set_setting_value "$rd_conf" "yuzu" "$(get_setting_value "$rd_defaults" "yuzu" "retrodeck" "ask_to_exit")" "retrodeck" "ask_to_exit"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
        dir_prep "$rd_home_bios_path/switch/keys" "$XDG_DATA_HOME/yuzu/keys"
        dir_prep "$rd_home_bios_path/switch/firmware" "$XDG_DATA_HOME/yuzu/nand/system/Contents/registered"
        dir_prep "$rd_home_saves_path/switch/yuzu/nand" "$XDG_DATA_HOME/yuzu/nand"
        dir_prep "$rd_home_saves_path/switch/yuzu/sdmc" "$XDG_DATA_HOME/yuzu/sdmc"
        dir_prep "$rd_internal_logs_path/yuzu" "$XDG_DATA_HOME/yuzu/log"
        dir_prep "$rd_home_screenshots_path" "$XDG_DATA_HOME/yuzu/screenshots"
        dir_prep "$mods_folder/Yuzu" "$XDG_DATA_HOME/yuzu/load"
        set_setting_value "$yuzuconf" "nand_directory" "$rd_home_saves_path/switch/yuzu/nand" "yuzu" "Data%20Storage"
        set_setting_value "$yuzuconf" "sdmc_directory" "$rd_home_saves_path/switch/yuzu/sdmc" "yuzu" "Data%20Storage"
        set_setting_value "$yuzuconf" "Paths\gamedirs\4\path" "$rd_home_roms_path/switch" "yuzu" "UI"
        set_setting_value "$yuzuconf" "Screenshots\screenshot_path" "$rd_home_screenshots_path" "yuzu" "UI"
    fi
    fi
fi

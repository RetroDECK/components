#!/bin/bash

component_name="$(basename "$(dirname "$0")")"
config="/app/retrodeck/config/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

    log i "----------------------"
    log i "Prepearing DOLPHIN"
    log i "----------------------"

    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        create_dir -d "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu"
        cp -fvr "$config/"* "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "BIOS" "$bios_folder" "dolphin" "GBA"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "SavesPath" "$saves_folder/gba" "dolphin" "GBA"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "ISOPath0" "$roms_folder/wii" "dolphin" "General"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "ISOPath1" "$roms_folder/gc" "dolphin" "General"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "WiiSDCardPath" "$saves_folder/wii/dolphin/sd.raw" "dolphin" "General"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu" "$XDG_CONFIG_HOME/dolphin-emu"
    else # Single-user actions
        create_dir -d "$XDG_CONFIG_HOME/dolphin-emu/"
        cp -fvr "$config/"* "$XDG_CONFIG_HOME/dolphin-emu/"
        set_setting_value "$dolphinconf" "BIOS" "$bios_folder" "dolphin" "GBA"
        set_setting_value "$dolphinconf" "SavesPath" "$saves_folder/gba" "dolphin" "GBA"
        set_setting_value "$dolphinconf" "ISOPath0" "$roms_folder/wii" "dolphin" "General"
        set_setting_value "$dolphinconf" "ISOPath1" "$roms_folder/gc" "dolphin" "General"
        set_setting_value "$dolphinconf" "WiiSDCardPath" "$saves_folder/wii/dolphin/sd.raw" "dolphin" "General"
    fi

    # Shared actions
    dir_prep "$saves_folder/gc/dolphin/EU" "$XDG_DATA_HOME/dolphin-emu/GC/EUR" # TODO: Multi-user one-off
    dir_prep "$saves_folder/gc/dolphin/US" "$XDG_DATA_HOME/dolphin-emu/GC/USA" # TODO: Multi-user one-off
    dir_prep "$saves_folder/gc/dolphin/JP" "$XDG_DATA_HOME/dolphin-emu/GC/JAP" # TODO: Multi-user one-off
    dir_prep "$screenshots_folder" "$XDG_DATA_HOME/dolphin-emu/ScreenShots"
    dir_prep "$states_folder/dolphin" "$XDG_DATA_HOME/dolphin-emu/StateSaves"
    dir_prep "$saves_folder/wii/dolphin" "$XDG_DATA_HOME/dolphin-emu/Wii"
    dir_prep "$mods_folder/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Load/GraphicMods"
    dir_prep "$texture_packs_folder/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Load/Textures"

    # Reset default preset settings
    set_setting_value "$rd_conf" "dolphin" "$(get_setting_value "$rd_defaults" "dolphin" "retrodeck" "ask_to_exit")" "retrodeck" "ask_to_exit"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
    dir_prep "$saves_folder/gc/dolphin/EU" "$XDG_DATA_HOME/dolphin-emu/GC/EUR"
    dir_prep "$saves_folder/gc/dolphin/US" "$XDG_DATA_HOME/dolphin-emu/GC/USA"
    dir_prep "$saves_folder/gc/dolphin/JP" "$XDG_DATA_HOME/dolphin-emu/GC/JAP"
    dir_prep "$screenshots_folder" "$XDG_DATA_HOME/dolphin-emu/ScreenShots"
    dir_prep "$states_folder/dolphin" "$XDG_DATA_HOME/dolphin-emu/StateSaves"
    dir_prep "$saves_folder/wii/dolphin" "$XDG_DATA_HOME/dolphin-emu/Wii"
    dir_prep "$mods_folder/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Load/GraphicMods"
    dir_prep "$texture_packs_folder/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Load/Textures"
    set_setting_value "$dolphinconf" "BIOS" "$bios_folder" "dolphin" "GBA"
    set_setting_value "$dolphinconf" "SavesPath" "$saves_folder/gba" "dolphin" "GBA"
    set_setting_value "$dolphinconf" "ISOPath0" "$roms_folder/wii" "dolphin" "General"
    set_setting_value "$dolphinconf" "ISOPath1" "$roms_folder/gc" "dolphin" "General"
    set_setting_value "$dolphinconf" "WiiSDCardPath" "$saves_folder/wii/dolphin/sd.raw" "dolphin" "General"
fi

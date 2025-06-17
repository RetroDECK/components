#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

dolphin_conf="$XDG_CONFIG_HOME/dolphin-emu/Dolphin.ini"
dolphin_gcpad_conf="$XDG_CONFIG_HOME/dolphin-emu/GCPadNew.ini"
dolphin_gfx_conf="$XDG_CONFIG_HOME/dolphin-emu/GFX.ini"
dolphin_hotkeys_conf="$XDG_CONFIG_HOME/dolphin-emu/Hotkeys.ini"
dolphin_qt_conf="$XDG_CONFIG_HOME/dolphin-emu/Qt.ini"
dolphin_dynamic_input_textures_path="$XDG_DATA_HOME/dolphin-emu/Load/DynamicInputTextures"
dolphin_cheevos_conf="$XDG_CONFIG_HOME/dolphin-emu/RetroAchievements.ini"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

    log i "----------------------"
    log i "Preparing $component_name"
    log i "----------------------"

    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        create_dir -d "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu"
        cp -fvr "$config/"* "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "BIOS" "$rd_home_bios_path" "dolphin" "GBA"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "SavesPath" "$rd_home_saves_path/gba" "dolphin" "GBA"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "ISOPath0" "$rd_home_roms_path/wii" "dolphin" "General"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "ISOPath1" "$rd_home_roms_path/gc" "dolphin" "General"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "WiiSDCardPath" "$rd_home_saves_path/wii/dolphin/sd.raw" "dolphin" "General"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu" "$XDG_CONFIG_HOME/dolphin-emu"
    else # Single-user actions
        create_dir -d "$XDG_CONFIG_HOME/dolphin-emu/"
        cp -fvr "$config/"* "$XDG_CONFIG_HOME/dolphin-emu/"
        set_setting_value "$dolphin_conf" "BIOS" "$rd_home_bios_path" "dolphin" "GBA"
        set_setting_value "$dolphin_conf" "SavesPath" "$rd_home_saves_path/gba" "dolphin" "GBA"
        set_setting_value "$dolphin_conf" "ISOPath0" "$rd_home_roms_path/wii" "dolphin" "General"
        set_setting_value "$dolphin_conf" "ISOPath1" "$rd_home_roms_path/gc" "dolphin" "General"
        set_setting_value "$dolphin_conf" "WiiSDCardPath" "$rd_home_saves_path/wii/dolphin/sd.raw" "dolphin" "General"
    fi

    # Shared actions
    dir_prep "$rd_home_saves_path/gc/dolphin/EU" "$XDG_DATA_HOME/dolphin-emu/GC/EUR" # TODO: Multi-user one-off
    dir_prep "$rd_home_saves_path/gc/dolphin/US" "$XDG_DATA_HOME/dolphin-emu/GC/USA" # TODO: Multi-user one-off
    dir_prep "$rd_home_saves_path/gc/dolphin/JP" "$XDG_DATA_HOME/dolphin-emu/GC/JAP" # TODO: Multi-user one-off
    dir_prep "$rd_home_screenshots_path" "$XDG_DATA_HOME/dolphin-emu/ScreenShots"
    dir_prep "$rd_home_states_path/dolphin" "$XDG_DATA_HOME/dolphin-emu/StateSaves"
    dir_prep "$rd_home_saves_path/wii/dolphin" "$XDG_DATA_HOME/dolphin-emu/Wii"
    dir_prep "$rd_home_mods_path/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Load/GraphicMods"
    dir_prep "$rd_home_texture_packs_path/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Load/Textures"

    # Reset default preset settings
    set_setting_value "$rd_conf" "dolphin" "$(get_setting_value "$rd_defaults" "dolphin" "retrodeck" "ask_to_exit")" "retrodeck" "ask_to_exit"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
    dir_prep "$rd_home_saves_path/gc/dolphin/EU" "$XDG_DATA_HOME/dolphin-emu/GC/EUR"
    dir_prep "$rd_home_saves_path/gc/dolphin/US" "$XDG_DATA_HOME/dolphin-emu/GC/USA"
    dir_prep "$rd_home_saves_path/gc/dolphin/JP" "$XDG_DATA_HOME/dolphin-emu/GC/JAP"
    dir_prep "$rd_home_screenshots_path" "$XDG_DATA_HOME/dolphin-emu/ScreenShots"
    dir_prep "$rd_home_states_path/dolphin" "$XDG_DATA_HOME/dolphin-emu/StateSaves"
    dir_prep "$rd_home_saves_path/wii/dolphin" "$XDG_DATA_HOME/dolphin-emu/Wii"
    dir_prep "$rd_home_mods_path/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Load/GraphicMods"
    dir_prep "$rd_home_texture_packs_path/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Load/Textures"
    set_setting_value "$dolphin_conf" "BIOS" "$rd_home_bios_path" "dolphin" "GBA"
    set_setting_value "$dolphin_conf" "SavesPath" "$rd_home_saves_path/gba" "dolphin" "GBA"
    set_setting_value "$dolphin_conf" "ISOPath0" "$rd_home_roms_path/wii" "dolphin" "General"
    set_setting_value "$dolphin_conf" "ISOPath1" "$rd_home_roms_path/gc" "dolphin" "General"
    set_setting_value "$dolphin_conf" "WiiSDCardPath" "$rd_home_saves_path/wii/dolphin/sd.raw" "dolphin" "General"
fi

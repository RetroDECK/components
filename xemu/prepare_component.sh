#!/bin/bash

if [[ "$component" =~ ^(xemu|all)$ ]]; then
component_found="true"
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
    log i "------------------------"
    log i "Prepearing XEMU"
    log i "------------------------"
    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$XDG_CONFIG_HOME/xemu"
        rm -rf "$XDG_DATA_HOME/xemu"
        create_dir -d "$multi_user_data_folder/$SteamAppUser/config/xemu/"
        cp -fv "$config/xemu/xemu.toml" "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "screenshot_dir" "'$screenshots_folder'" "xemu" "General"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "bootrom_path" "'$bios_folder/mcpx_1.0.bin'" "xemu" "sys.files"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "flashrom_path" "'$bios_folder/Complex.bin'" "xemu" "sys.files"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "eeprom_path" "'$saves_folder/xbox/xemu/xbox-eeprom.bin'" "xemu" "sys.files"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "hdd_path" "'$bios_folder/xbox_hdd.qcow2'" "xemu" "sys.files"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/xemu" "$XDG_CONFIG_HOME/xemu" # Creating config folder in $XDG_CONFIG_HOME for consistentcy and linking back to original location where component will look
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/xemu" "$XDG_DATA_HOME/xemu/xemu"
    else # Single-user actions
        rm -rf "$XDG_CONFIG_HOME/xemu"
        rm -rf "$XDG_DATA_HOME/xemu"
        dir_prep "$XDG_CONFIG_HOME/xemu" "$XDG_DATA_HOME/xemu/xemu" # Creating config folder in $XDG_CONFIG_HOME for consistentcy and linking back to original location where component will look
        cp -fv "$config/xemu/xemu.toml" "$xemuconf"
        set_setting_value "$xemuconf" "screenshot_dir" "'$screenshots_folder'" "xemu" "General"
        set_setting_value "$xemuconf" "bootrom_path" "'$bios_folder/mcpx_1.0.bin'" "xemu" "sys.files"
        set_setting_value "$xemuconf" "flashrom_path" "'$bios_folder/Complex.bin'" "xemu" "sys.files"
        set_setting_value "$xemuconf" "eeprom_path" "'$saves_folder/xbox/xemu/xbox-eeprom.bin'" "xemu" "sys.files"
        set_setting_value "$xemuconf" "hdd_path" "'$bios_folder/xbox_hdd.qcow2'" "xemu" "sys.files"
    fi # Shared actions
    create_dir "$saves_folder/xbox/xemu/"
    # Preparing HD dummy Image if the image is not found
    if [ ! -f "$bios_folder/xbox_hdd.qcow2" ]
    then
        cp -f "/app/retrodeck/extras/XEMU/xbox_hdd.qcow2" "$bios_folder/xbox_hdd.qcow2"
    fi
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
    set_setting_value "$xemuconf" "screenshot_dir" "'$screenshots_folder'" "xemu" "General"
    set_setting_value "$xemuconf" "bootrom_path" "'$bios_folder/mcpx_1.0.bin'" "xemu" "sys.files"
    set_setting_value "$xemuconf" "flashrom_path" "'$bios_folder/Complex.bin'" "xemu" "sys.files"
    set_setting_value "$xemuconf" "eeprom_path" "'$saves_folder/xbox/xemu/xbox-eeprom.bin'" "xemu" "sys.files"
    set_setting_value "$xemuconf" "hdd_path" "'$bios_folder/xbox_hdd.qcow2'" "xemu" "sys.files"
    fi
fi
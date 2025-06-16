#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

    log i "------------------------"
    log i "Preparing $component_name"
    log i "------------------------"

    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$XDG_CONFIG_HOME/xemu"
        rm -rf "$XDG_DATA_HOME/xemu"
        create_dir -d "$multi_user_data_folder/$SteamAppUser/config/xemu/"
        cp -fv "$config/xemu.toml" "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "screenshot_dir" "'$rd_home_screenshots_path'" "xemu" "General"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "bootrom_path" "'$rd_home_bios_path/mcpx_1.0.bin'" "xemu" "sys.files"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "flashrom_path" "'$rd_home_bios_path/Complex.bin'" "xemu" "sys.files"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "eeprom_path" "'$rd_home_saves_path/xbox/xemu/xbox-eeprom.bin'" "xemu" "sys.files"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "hdd_path" "'$rd_home_bios_path/xbox_hdd.qcow2'" "xemu" "sys.files"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/xemu" "$XDG_CONFIG_HOME/xemu" # Creating config folder in $XDG_CONFIG_HOME for consistentcy and linking back to original location where component will look
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/xemu" "$XDG_DATA_HOME/xemu/xemu"

    else # Single-user actions

        rm -rf "$XDG_CONFIG_HOME/xemu"
        rm -rf "$XDG_DATA_HOME/xemu"
        dir_prep "$XDG_CONFIG_HOME/xemu" "$XDG_DATA_HOME/xemu/xemu" # Creating config folder in $XDG_CONFIG_HOME for consistentcy and linking back to original location where component will look
        cp -fv "$config/xemu.toml" "$xemu_config"
        set_setting_value "$xemu_config" "screenshot_dir" "'$rd_home_screenshots_path'" "xemu" "General"
        set_setting_value "$xemu_config" "bootrom_path" "'$rd_home_bios_path/mcpx_1.0.bin'" "xemu" "sys.files"
        set_setting_value "$xemu_config" "flashrom_path" "'$rd_home_bios_path/Complex.bin'" "xemu" "sys.files"
        set_setting_value "$xemu_config" "eeprom_path" "'$rd_home_saves_path/xbox/xemu/xbox-eeprom.bin'" "xemu" "sys.files"
        set_setting_value "$xemu_config" "hdd_path" "'$rd_home_bios_path/xbox_hdd.qcow2'" "xemu" "sys.files"
    fi
    
    # Shared actions
    create_dir "$rd_home_saves_path/xbox/xemu/"

    # Preparing HD dummy Image if the image is not found
    if [ ! -f "$rd_home_bios_path/xbox_hdd.qcow2" ];then
        cp -f "/app/retrodeck/extras/XEMU/xbox_hdd.qcow2" "$rd_home_bios_path/xbox_hdd.qcow2"
    fi

fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
    set_setting_value "$xemu_config" "screenshot_dir" "'$rd_home_screenshots_path'" "xemu" "General"
    set_setting_value "$xemu_config" "bootrom_path" "'$rd_home_bios_path/mcpx_1.0.bin'" "xemu" "sys.files"
    set_setting_value "$xemu_config" "flashrom_path" "'$rd_home_bios_path/Complex.bin'" "xemu" "sys.files"
    set_setting_value "$xemu_config" "eeprom_path" "'$rd_home_saves_path/xbox/xemu/xbox-eeprom.bin'" "xemu" "sys.files"
    set_setting_value "$xemu_config" "hdd_path" "'$rd_home_bios_path/xbox_hdd.qcow2'" "xemu" "sys.files"
fi

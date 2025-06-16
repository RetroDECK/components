#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

    log i "----------------------"
    log i "Preparing $component_name"
    log i "----------------------"

    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions


    else # Single-user actions
    
        create_dir -d "$XDG_CONFIG_HOME/azahar/"
        cp -fvr "$config/azahar/qt-config.ini" "$XDG_CONFIG_HOME/azahar/"
        set_setting_value "$azahar_config" "nand_directory" "$rd_home_saves_path/n3ds/azahar/nand/" "azahar"
        set_setting_value "$azahar_config" "nand_directory" "$rd_home_saves_path/n3ds/azahar/sdmc/" "azahar"
        set_setting_value "$azahar_config" "Paths\gamedirs\3\path" "$rd_home_roms_path/n3ds" "azahar"
        set_setting_value "$azahar_config" "Paths\screenshotPath" "$rd_home_screenshots_path/n3ds/azahar" "azahar"



    fi

    # Shared actions
    create_dir "$rd_home_screenshots_path/n3ds/azahar"
    create_dir "$rd_home_saves_path/n3ds/azahar/nand/"
    create_dir "$rd_home_saves_path/n3ds/azahar/sdmc/"

fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands

fi

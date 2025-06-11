#!/bin/bash

component_name="$(basename "$(dirname "$0")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

    log i "----------------------"
    log i "Prepearing Azahar"
    log i "----------------------"

    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions


    else # Single-user actions
    
        create_dir -d "$XDG_CONFIG_HOME/azahar/"
        cp -fvr "$config/azahar/qt-config.ini" "$XDG_CONFIG_HOME/azahar/"
        set_setting_value "$azaharconf" "nand_directory" "$saves_folder/n3ds/azahar/nand/"
        set_setting_value "$azaharconf" "nand_directory" "$saves_folder/n3ds/azahar/sdmc/"
        set_setting_value "$azaharconf" "Paths\gamedirs\3\path" "$roms_folder/n3ds"
        set_setting_value "$azaharconf" "Paths\screenshotPath" "$screenshots_folder/n3ds/azahar"



    fi

    # Shared actions
    create_dir "$screenshots_folder/n3ds/azahar"
    create_dir "$saves_folder/n3ds/azahar/nand/"
    create_dir "$saves_folder/n3ds/azahar/sdmc/"

fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands

fi

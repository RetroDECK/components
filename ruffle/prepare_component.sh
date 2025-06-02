#!/bin/bash

if [[ "$component" == "retrodeck" ]]; then
    component_found="true"
    log i "--------------------------------"
    log i "Prepearing Ruffle"
    log i "--------------------------------"
    if [[ "$action" == "reset" ]]; then # Update the paths of all folders in retrodeck.cfg and create them
        create_dir "$saves_folder/ruffle"
    fi
fi
#!/bin/bash

component_name="$(basename "$(dirname "$0")")"

log i "--------------------------------"
log i "Prepearing Ruffle"
log i "--------------------------------"
if [[ "$action" == "reset" ]]; then
    create_dir "$saves_folder/ruffle"
fi
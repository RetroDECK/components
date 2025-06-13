#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"

log i "--------------------------------"
log i "Prepearing Ruffle"
log i "--------------------------------"
if [[ "$action" == "reset" ]]; then
    create_dir "$saves_folder/ruffle"
fi

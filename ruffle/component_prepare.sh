#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"

log i "--------------------------------"
log i "Preparing $component_name"
log i "--------------------------------"
if [[ "$action" == "reset" ]]; then
    create_dir "$rd_home_saves_path/ruffle"
fi

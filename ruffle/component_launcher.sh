#!/bin/bash

arg="$@"

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

log i "RetroDECK is now launching $component_name"
log i "Ruffle is running: $arg"

static_invoke="--config /var/data/ruffle --save-directory $saves_path/ruffle"

#Check if Steam Deck in Desktop Mode
if [[ $(check_desktop_mode) == "true" ]]; then
    log d "Running Ruffle in Desktop Mode"
    log d "ruffle --graphics vulkan $static_invoke $@"
    exec "$component_path/bin/ruffle" --graphics vulkan $static_invoke "$@"
else
    log d "Running Ruffle in Gaming Mode"
    log d "ruffle --graphics gl --no-gui $static_invoke $@"
    exec "$component_path/bin/ruffle" --graphics gl --no-gui $static_invoke "$@"
fi

#!/bin/bash

source /app/libexec/global.sh
source /app/libexec/logger.sh

arg="$@"

COMPONENT_NAME="ruffle"
COMPONENT_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

log i "RetroDECK is now launching $COMPONENT_NAME"
log i "Ruffle is running: $arg"

static_invoke="--config /var/data/ruffle --save-directory $saves_folder/ruffle --fullscreen"

#Check if Steam Deck in Desktop Mode
if [[ $(check_desktop_mode) == "true" ]]; then
    log d "Running Ruffle in Desktop Mode"
    log d "ruffle --graphics vulkan $static_invoke $@"
    exec "$COMPONENT_FOLDER/ruffle" --graphics vulkan $static_invoke "$@"
else
    log d "Running Ruffle in Gaming Mode"
    log d "ruffle --graphics gl --no-gui $static_invoke $@"
    exec "$COMPONENT_FOLDER/ruffle" --graphics gl --no-gui $static_invoke "$@"
fi

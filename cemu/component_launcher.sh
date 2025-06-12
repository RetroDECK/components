#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="cemu"
COMPONENT_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

source "$COMPONENT_FOLDER/apprun-hooks/linuxdeploy-plugin-checkrt.sh"
source "$COMPONENT_FOLDER/apprun-hooks/linuxdeploy-plugin-gtk.sh"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-checkrt.sh"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-gtk.sh"

exec "$COMPONENT_FOLDER/bin/Cemu" "$@"

#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="pcsx2"
COMPONENT_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

source "$COMPONENT_FOLDER/apprun-hooks/linuxdeploy-plugin-qt-hook.sh"
source "$COMPONENT_FOLDER/apprun-hooks/default-to-x11.sh"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-qt-hook.sh"
log d "Loaded app run hooks in apprun-hooks/default-to-x11.sh"

exec "$COMPONENT_FOLDER/bin/pcsx2-qt" "$@"

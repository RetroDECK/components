#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="duckstation"
COMPONENT_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

source "$COMPONENT_FOLDER/apprun-hooks/linuxdeploy-plugin-qt-hook.sh"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-qt-hook.sh"

exec "$COMPONENT_FOLDER/bin/duckstation-qt" "$@"

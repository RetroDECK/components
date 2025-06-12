#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="steam-rom-manager"
COMPONENT_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
IN_FLATPAK=1

LD_LIBRARY_PATH="$COMPONENT_FOLDER/lib:${LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $COMPONENT_FOLDER"

exec "$COMPONENT_FOLDER/AppRun" --no-sandbox "$@"

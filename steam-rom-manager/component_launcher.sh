#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="steam-rom-manager"
IN_FLATPAK=1

# This ensures the application can find its resources
export APPDIR="$rd_components/$COMPONENT_NAME"

LD_LIBRARY_PATH="$rd_components/$COMPONENT_NAME/lib:${LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $APPDIR"

exec "$rd_components/$COMPONENT_NAME/AppRun" --no-sandbox "$@"

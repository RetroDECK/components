#!/bin/bash

source /app/libexec/logger.sh

RD_MODULES="/app/retrodeck/components"
COMPONENT_NAME="steam-rom-manager"
IN_FLATPAK=1

# This ensures the application can find its resources
export APPDIR="$RD_MODULES/$COMPONENT_NAME"

LD_LIBRARY_PATH="$RD_MODULES/$COMPONENT_NAME/lib:${LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $APPDIR"

exec "$RD_MODULES/$COMPONENT_NAME/AppRun" --no-sandbox "$@"

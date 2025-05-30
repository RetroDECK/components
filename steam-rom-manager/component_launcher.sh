#!/bin/bash

RD_MODULES="/app/retrodeck/components"
COMPONENT_NAME="steam-rom-manager"
IN_FLATPAK=1

# This ensures the application can find its resources
export APPDIR="$RD_MODULES/$COMPONENT_NAME"

LD_LIBRARY_PATH="$RD_MODULES/$COMPONENT_NAME/lib:${LD_LIBRARY_PATH}"

exec "$RD_MODULES/$COMPONENT_NAME/AppRun" --no-sandbox "$@"

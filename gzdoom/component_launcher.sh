#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="gzdoom"
RD_MODULES="/app/retrodeck/components"

# This ensures the application can find its resources
export APPDIR="$RD_MODULES/$COMPONENT_NAME"

LD_LIBRARY_PATH="$RD_MODULES/$COMPONENT_NAME/lib:${LD_LIBRARY_PATH}"
export DOOMWADDIR="$RD_MODULES/$COMPONENT_NAME/share/games/doom"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"
log d "DOOM WADs directory is: $DOOMWADDIR"

exec "$RD_MODULES/$COMPONENT_NAME/AppRun" --no-sandbox +fluid_patchset "$RD_MODULES/$COMPONENT_NAME/share/games/doom/soundfonts/gzdoom.sf2" "$@"
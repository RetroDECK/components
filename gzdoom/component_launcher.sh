#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="gzdoom"

# This ensures the application can find its resources
export APPDIR="$rd_components/$COMPONENT_NAME"

LD_LIBRARY_PATH="$rd_components/$COMPONENT_NAME/lib:${LD_LIBRARY_PATH}"
export DOOMWADDIR="$rd_components/$COMPONENT_NAME/share/games/doom"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"
log d "DOOM WADs directory is: $DOOMWADDIR"

exec "$rd_components/$COMPONENT_NAME/AppRun" --no-sandbox +fluid_patchset "$rd_components/$COMPONENT_NAME/share/games/doom/soundfonts/gzdoom.sf2" "$@"

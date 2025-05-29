#!/bin/bash

COMPONENT_NAME="gzdoom"
RD_MODULES="/app/retrodeck/components"

# This ensures the application can find its resources
export APPDIR="$RD_MODULES/$COMPONENT_NAME"

LD_LIBRARY_PATH="$RD_MODULES/$COMPONENT_NAME/lib:${LD_LIBRARY_PATH}"
export DOOMWADDIR="$RD_MODULES/$COMPONENT_NAME/share/games/doom"

exec "$RD_MODULES/$COMPONENT_NAME/AppRun" --no-sandbox +fluid_patchset "$RD_MODULES/$COMPONENT_NAME/share/games/doom/soundfonts/gzdoom.sf2" "$@"
#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="rpcs3"
RD_MODULES="/app/retrodeck/components"

# This ensures the application can find its resources
export APPDIR="$RD_MODULES/$COMPONENT_NAME"

LD_LIBRARY_PATH="$RD_MODULES/$COMPONENT_NAME/lib:${LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $APPDIR"

# NOTE: AppRun is not working for RPCS3
exec "$RD_MODULES/$COMPONENT_NAME/bin/rpcs3" "$@"
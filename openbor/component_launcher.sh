#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="openbor"

# This ensures the application can find its resources
export APPDIR="$rd_components/$COMPONENT_NAME"

LD_LIBRARY_PATH="$rd_components/$COMPONENT_NAME/lib"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $APPDIR"

exec "$rd_components/$COMPONENT_NAME/bin/OpenBOR" "$@"

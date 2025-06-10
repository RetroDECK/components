#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="ryubing"

LD_LIBRARY_PATH="$rd_components/$COMPONENT_NAME/lib:${LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"

exec "$rd_components/$COMPONENT_NAME/usr/bin/Ryujinx.sh" "$@"

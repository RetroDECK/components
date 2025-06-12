#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="vpinballx-bgfx"
COMPONENT_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

LD_LIBRARY_PATH="$COMPONENT_FOLDER/"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $COMPONENT_FOLDER"

exec "$COMPONENT_FOLDER/VPinballX_BGFX" "$@"

#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="mudlet"
COMPONENT_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

LD_LIBRARY_PATH="$COMPONENT_FOLDER/lib:$rd_shared_libs/qt-5.15/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$rd_shared_libs/qt-5.15/lib/plugins:${QT_PLUGIN_PATH}"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $COMPONENT_FOLDER"

# NOTE: AppRun is not working for Mudlet
exec "$COMPONENT_FOLDER/mudlet" "$@"

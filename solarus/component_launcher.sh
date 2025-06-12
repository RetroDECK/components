#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="solarus"
COMPONENT_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

LD_LIBRARY_PATH="$COMPONENT_FOLDER/lib:/app/retrodeck/components/shared-libs/qt-5.15/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="/app/retrodeck/components/shared-libs/qt-5.15/lib/plugins:${QT_PLUGIN_PATH}"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"
log d "QT plugin path is: $QT_PLUGIN_PATH"

exec "$COMPONENT_FOLDER/bin/solarus-launcher" "$@"

#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="solarus"

LD_LIBRARY_PATH="$rd_components/$COMPONENT_NAME/lib:$rd_shared_libs/qt-5.15/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$rd_shared_libs/qt-5.15/lib/plugins:${QT_PLUGIN_PATH}"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"
log d "QT plugin path is: $QT_PLUGIN_PATH"

exec "$rd_components/$COMPONENT_NAME/bin/solarus-launcher" "$@"

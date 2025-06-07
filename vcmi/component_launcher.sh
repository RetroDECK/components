#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="vcmi"

rd_shared_libs="/app/retrodeck/components/shared-libs/qt-6.8/lib"

LD_LIBRARY_PATH="$rd_components/$COMPONENT_NAME/lib:$rd_shared_libs/qt-6.8/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$rd_shared_libs/qt-6.8/lib/plugins:${QT_PLUGIN_PATH}"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $APPDIR"

exec "$rd_components/$COMPONENT_NAME/bin/vcmilauncher" "$@"

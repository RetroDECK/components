#!/bin/bash

source /app/libexec/logger.sh

component_name="shadps4"

# This ensures the application can find its resources
export APPDIR="$rd_components/$component_name"

LD_LIBRARY_PATH="$rd_components/$component_name/lib:$rd_shared_libs/qt-6.8/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$rd_shared_libs/qt-6.8/lib/plugins:${QT_PLUGIN_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $APPDIR"

exec "$components_path/$component_name/bin/shadps4" "$@"

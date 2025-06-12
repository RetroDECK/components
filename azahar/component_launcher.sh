#!/bin/bash

source /app/libexec/logger.sh

component_name="azahar"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

LD_LIBRARY_PATH="$component_path/lib:/app/retrodeck/components/shared-libs/qt-6.8/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$rd_rd_shared_libs/qt-6.8/lib/plugins:${QT_PLUGIN_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $component_path"

exec "$component_path/usr/bin/azahar" "$@"

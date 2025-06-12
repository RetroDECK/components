#!/bin/bash

source /app/libexec/logger.sh

component_name="shadps4"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

# set LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$component_path/lib:/app/retrodeck/components/shared-libs/qt-6.8/lib:${LD_LIBRARY_PATH}"

# set plugin paths
export QT_PLUGIN_PATH="/app/retrodeck/components/shared-libs/plugins:${QT_PLUGIN_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="/app/retrodeck/components/shared-libs/qt-6.8/lib/plugins/platforms"

log i "Retrodeck is now launching $component_name"
log d "Library Path: $LD_LIBRARY_PATH"
log d "QT Plugin Path: $QT_PLUGIN_PATH"
log d "QT QPA Platform Plugin Path is: $QT_QPA_PLATFORM_PLUGIN_PATH"

exec "$component_path/$component_name/bin/shadps4" "$@"

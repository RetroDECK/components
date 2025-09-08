#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

# Set LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$component_path/lib:$rd_shared_libs/qt-6.8/lib:${LD_LIBRARY_PATH}"

# Set plugin paths
export QT_PLUGIN_PATH="$rd_shared_libs/plugins:${QT_PLUGIN_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="$rd_shared_libs/qt-6.8/lib/plugins/platforms"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "QT plugin path is: $QT_PLUGIN_PATH"
log d "QT QPA PLATFORM plugin path is: $QT_QPA_PLATFORM_PLUGIN_PATH"

exec "$component_path/usr/bin/eka2l1_qt" "$@"

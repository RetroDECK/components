#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

export LD_LIBRARY_PATH="$component_path/lib:$rd_shared_libs:$rd_shared_libs/org.kde.Platform/6.9:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$component_path/plugins/:${QT_PLUGIN_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="$component_path/plugins/platforms/:${QT_QPA_PLATFORM_PLUGIN_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "QT plugin path is: $QT_PLUGIN_PATH"

exec "$component_path/bin/solarus-launcher" "$@"

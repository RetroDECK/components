#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

source "$component_path/apprun-hooks/linuxdeploy-plugin-qt-hook.sh"

export LD_LIBRARY_PATH="$component_path/lib:${DEFAULT_LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$component_path/plugins/:${QT_PLUGIN_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="$component_path/lib/plugins/platforms/:${QT_QPA_PLATFORM_PLUGIN_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "QT plugin path is: $QT_PLUGIN_PATH"

log i "RetroDECK is now launching $component_name"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-qt-hook.sh"

exec "$component_path/bin/pcsx2-qt" "$@"

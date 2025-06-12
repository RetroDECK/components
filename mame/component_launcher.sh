#!/bin/bash

source /app/libexec/logger.sh

component_name="mame"
component_folder_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

component_library_path="$component_folder_path/lib:/app/retrodeck/components/shared-libs/qt-6.8/lib:${component_library_path}"
export qt_plugin_path="/app/retrodeck/components/shared-libs/qt-6.8/lib/plugins:${qt_plugin_path}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $component_library_path"
log d "QT plugin path is: $qt_plugin_path"

exec "$component_folder_path/bin/mame" "$@"

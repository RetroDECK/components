#!/bin/bash

source /app/libexec/logger.sh

component_name="mudlet"
component_folder_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

component_library_path="$component_folder_path/lib:/app/retrodeck/components/shared-libs/qt-5.15/lib:${component_library_path}"
export qt_plugin_path="/app/retrodeck/components/shared-libs/qt-5.15/lib/plugins:${qt_plugin_path}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $component_library_path"
log d "AppDir is: $component_folder_path"

# NOTE: AppRun is not working for Mudlet
exec "$component_folder_path/mudlet" "$@"

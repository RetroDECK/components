#!/bin/bash

source /app/libexec/logger.sh

component_name="shadps4"
component_folder_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

# set component_library_path
export component_library_path="$component_folder_path/lib:/app/retrodeck/components/shared-libs/qt-6.8/lib:${component_library_path}"

# set plugin paths
export qt_plugin_path="/app/retrodeck/components/shared-libs/plugins:${qt_plugin_path}"
export qt_qpa_platform_plugin_path="/app/retrodeck/components/shared-libs/qt-6.8/lib/plugins/platforms"

log i "Retrodeck is now launching $component_name"
log d "Library Path: $component_library_path"
log d "QT Plugin Path: $qt_plugin_path"
log d "QT QPA Platform Plugin Path is: $qt_qpa_platform_plugin_path"

exec "$components_path/$component_name/bin/shadps4" "$@"

#!/bin/bash

source /app/libexec/logger.sh

component_name="mudlet"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

LD_LIBRARY_PATH="$component_path/lib:/app/retrodeck/components/shared-libs/qt-5.15/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="/app/retrodeck/components/shared-libs/qt-5.15/lib/plugins:${QT_PLUGIN_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $component_path"

# NOTE: AppRun is not working for Mudlet
exec "$component_path/mudlet" "$@"

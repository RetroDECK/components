#!/bin/bash

source /app/libexec/logger.sh

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

LD_LIBRARY_PATH="$component_path/lib:/app/retrodeck/components/shared-libs/qt-6.7/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="/app/retrodeck/components/shared-libs/qt-6.7/lib/plugins:${QT_PLUGIN_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "QT plugin path is: $QT_PLUGIN_PATH"

exec "$component_path/es-de" --home "$XDG_CONFIG_HOME" "$@"

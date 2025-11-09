#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

export LD_LIBRARY_PATH="$component_path/lib:$rd_shared_libs/org.kde.Platform/6.10/:${LD_LIBRARY_PATH}"

export QT_PLUGIN_PATH="$rd_shared_libs/org.kde.Platform/6.10/plugins/:${QT_PLUGIN_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="$rd_shared_libs/shared-libs/org.kde.Platform/6.10/plugins/platforms/:${QT_QPA_PLATFORM_PLUGIN_PATH}"


log i "RetroDECK is now launching $component_name"

exec "$component_path/bin/retroarch" "$@"

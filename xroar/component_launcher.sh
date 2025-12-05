#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

export LD_LIBRARY_PATH="$component_path/lib:$ffmpeg_path/25.08:$rd_shared_libs:$rd_shared_libs/org.kde.Platform/6.10/:$rd_shared_libs/org.gnome.Platform/49/:$rd_shared_libs/org.freedesktop.Platform/25.08/:${DEFAULT_LD_LIBRARY_PATH}"
export XROAR_CONF_PATH="$XDG_CONFIG_HOME/xroar"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $component_path"

log d "Executing: $component_path/bin/xroar -c $xroar_config $*"

exec "$component_path/bin/xroar" -joy-db-file "gamecontrollerdb.txt" "$@"

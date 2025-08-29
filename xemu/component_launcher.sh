#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

unset QEMU_AUDIO_DRV

export LD_LIBRARY_PATH="$component_path/lib:$rd_shared_libs/qt-6.8/lib:${LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $APPDIR"

exec "$component_path/bin/xemu" "$@"

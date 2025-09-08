#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

source "$component_path/apprun-hooks/linuxdeploy-plugin-qt-hook.sh"
source "$component_path/apprun-hooks/default-to-x11.sh"

export LD_LIBRARY_PATH="$component_path/lib:${LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Loaded app run hooks in apprun-hooks/linuxdeploy-plugin-qt-hook.sh"
log d "Loaded app run hooks in apprun-hooks/default-to-x11.sh"

exec "$component_path/usr/bin/pcsx2-qt" "$@"

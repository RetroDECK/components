#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $component_path"

export LD_LIBRARY_PATH="$component_path/lib:$component_path/shared-libs:$component_path/shared-libs/org.kde.Platform/6.10/:$component_path/shared-libs/org.gnome.Platform/49/:$component_path/shared-libs/org.freedesktop.Platform/25.08/:${LD_LIBRARY_PATH}"

exec "$component_path/bin/Cemu_relwithdebinfo" "$@"
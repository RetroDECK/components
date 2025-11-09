#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

export LD_LIBRARY_PATH="$component_path/lib:$component_path/lib/org.kde.Platform/6.10/:$component_path/lib/org.gnome.Platform/49/:$component_path/lib/org.freedesktop.Platform/25.08/:${LD_LIBRARY_PATH}"
PATH="$component_path/bin:$PATH"

# Ensure bundled share files are discoverable inside the Flatpak runtime
export XDG_DATA_DIRS="$component_path/share:${XDG_DATA_DIRS}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"

exec "$component_path/bin/Vita3K" "$@"

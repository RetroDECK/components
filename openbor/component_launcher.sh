#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

export LD_LIBRARY_PATH="$component_path/lib:$rd_shared_libs:${LD_LIBRARY_PATH}"

PATH="$component_path/bin:$PATH"

# Ensure bundled share files are discoverable inside the Flatpak runtime
export XDG_DATA_DIRS="$component_path/share:${XDG_DATA_DIRS}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"

exec "$component_path/bin/OpenBOR" "$@"

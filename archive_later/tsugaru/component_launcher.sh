#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

# Set LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$component_path/lib:$ffmpeg_path/25.08:$rd_shared_libs/org.gnome.Platform/49/:${DEFAULT_LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"

exec "$component_path/Tsugaru_CUI" "$@"

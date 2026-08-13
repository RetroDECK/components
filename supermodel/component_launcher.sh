#!/bin/bash

source /app/libexec/launcher_functions.sh

# Wayland fix

WAYLAND_DISPLAY=""

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

# Set LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$component_path/lib:${DEFAULT_LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"

# Launch
exec "$component_path/bin/supermodel" -fullscreen "$@"

#!/bin/bash

source /app/libexec/launcher_functions.sh

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

export LD_LIBRARY_PATH="$component_path/lib:$rd_shared_libs:${DEFAULT_LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"

exec "$component_path/quake3e-vulkan.x64" +set fs_basepath /var/data/quake3e/baseq3 +set in_joystick 1 +set r_fullscreen 1 +set fs_homepath /var/config/quake3e/ "$@"

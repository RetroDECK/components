#!/bin/bash

source /app/libexec/launcher_functions.sh

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

export LD_LIBRARY_PATH="$component_path/lib:$rd_shared_libs:${DEFAULT_LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "DOOM WADs directory is: $DOOMWADDIR"

exec "$component_path/dhewm3" +set fs_gameDllPath /app/retrodeck/components/dhewm3 +set fs_basepath /var/data/dhewm3/base +set r_fullscreen 1 "$@"

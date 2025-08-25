#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

export LD_LIBRARY_PATH="$component_path/lib:${LD_LIBRARY_PATH}"
export DOOMWADDIR="$component_path/share/games/doom"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "DOOM WADs directory is: $DOOMWADDIR"

APPDIR="$component_path" exec "$component_path/AppRun" --no-sandbox +fluid_patchset "$component_path/share/games/doom/soundfonts/gzdoom.sf2" "$@"

#!/bin/bash

source /app/libexec/logger.sh

component_name="gzdoom"
component_folder_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

component_library_path="$component_folder_path/lib:${component_library_path}"
export DOOMWADDIR="$component_folder_path/share/games/doom"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $component_library_path"
log d "DOOM WADs directory is: $DOOMWADDIR"

exec "$component_folder_path/AppRun" --no-sandbox +fluid_patchset "$component_folder_path/share/games/doom/soundfonts/gzdoom.sf2" "$@"

#!/bin/bash

source /app/libexec/logger.sh

component_name="steam-rom-manager"
component_folder_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
IN_FLATPAK=1

component_library_path="$component_folder_path/lib:${component_library_path}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $component_library_path"
log d "AppDir is: $component_folder_path"

exec "$component_folder_path/AppRun" --no-sandbox "$@"

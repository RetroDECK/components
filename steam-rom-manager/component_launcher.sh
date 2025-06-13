#!/bin/bash

source /app/libexec/logger.sh

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
IN_FLATPAK=1

LD_LIBRARY_PATH="$component_path/lib:${LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $component_path"

exec "$component_path/AppRun" --no-sandbox "$@"

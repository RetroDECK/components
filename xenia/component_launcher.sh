#!/bin/bash

source /app/libexec/logger.sh

component_name="xenia"
component_folder_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

LD_LIBRARY_PATH="$component_folder_path/"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $component_folder_path"

exec "$component_folder_path/xenia_canary" "$@"

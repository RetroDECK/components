#!/bin/bash

source /app/libexec/logger.sh

component_name="rpcs3"
component_folder_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

LD_LIBRARY_PATH="$component_folder_path/lib:${LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $component_folder_path"

# NOTE: AppRun is not working for RPCS3
exec "$component_folder_path/bin/rpcs3" "$@"

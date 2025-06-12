#!/bin/bash

source /app/libexec/logger.sh

component_name="ryubing"
component_folder_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

component_library_path="$component_folder_path/lib:${component_library_path}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $component_library_path"

exec "$component_folder_path/usr/bin/Ryujinx.sh" "$@"

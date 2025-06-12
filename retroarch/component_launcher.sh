#!/bin/bash

source /app/libexec/logger.sh

component_name="retroarch"
component_folder_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

log i "RetroDECK is now launching $component_name"

exec "$component_folder_path/bin/retroarch" "$@"

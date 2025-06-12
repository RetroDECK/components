#!/bin/bash

source /app/libexec/logger.sh

component_name="ppsspp"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

LD_LIBRARY_PATH="$component_path/lib:${LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"

exec "$component_path/bin/PPSSPPSDL" "$@"

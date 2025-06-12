#!/bin/bash

source /app/libexec/logger.sh

component_name="vita3k"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

LD_LIBRARY_PATH="$component_path/lib:${LD_LIBRARY_PATH}"
PATH="$component_path/bin:$PATH"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"

exec "$component_path/bin/Vita3K" "$@"

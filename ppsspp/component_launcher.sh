#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

export LD_LIBRARY_PATH="$component_path/lib:$rd_shared_libs/qt-6.8/lib:${LD_LIBRARY_PATH}"

# Workaround for vDSO issues in some environments
export LD_PRELOAD=""
unset LD_PRELOAD

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"

exec "$component_path/bin/PPSSPPSDL" "$@"

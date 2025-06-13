#!/bin/bash

source /app/libexec/logger.sh

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

unset QEMU_AUDIO_DRV

log i "RetroDECK is now launching $component_name"

exec "exec "$component_path/bin/xemu" --no-sandbox "$@"

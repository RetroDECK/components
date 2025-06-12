#!/bin/bash

source /app/libexec/logger.sh

component_name="xemu"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

unset QEMU_AUDIO_DRV

log i "RetroDECK is now launching $component_name"

exec "exec "$component_path/bin/xemu" --no-sandbox "$@"

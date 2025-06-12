#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="xemu"
COMPONENT_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

unset QEMU_AUDIO_DRV

log i "RetroDECK is now launching $COMPONENT_NAME"

exec "$COMPONENT_FOLDER/AppRun" --no-sandbox "$@"

#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="xemu"

unset QEMU_AUDIO_DRV

log i "RetroDECK is now launching $COMPONENT_NAME"

exec "$rd_components/$COMPONENT_NAME/AppRun" --no-sandbox "$@"

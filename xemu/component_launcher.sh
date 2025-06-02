#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="xemu"
RD_MODULES="/app/retrodeck/components"

unset QEMU_AUDIO_DRV

log i "RetroDECK is now launching $COMPONENT_NAME"

exec "$RD_MODULES/$COMPONENT_NAME/AppRun" --no-sandbox "$@"
#!/bin/bash

COMPONENT_NAME="xemu"
RD_MODULES="/app/retrodeck/components"

unset QEMU_AUDIO_DRV

exec "$RD_MODULES/$COMPONENT_NAME/AppRun" --no-sandbox "$@"
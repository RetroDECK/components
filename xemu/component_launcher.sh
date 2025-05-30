#!/bin/bash

RD_MODULES="/app/retrodeck/components"
COMPONENT_NAME="xemu"

unset QEMU_AUDIO_DRV

exec "$RD_MODULES/$COMPONENT_NAME/AppRun" --no-sandbox "$@"
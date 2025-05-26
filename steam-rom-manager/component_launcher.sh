#!/bin/bash

RD_MODULES="/app/retrodeck/components"

LD_LIBRARY_PATH="$RD_MODULES/steam-rom-manager/lib:${LD_LIBRARY_PATH}"

exec "$RD_MODULES/steam-rom-manager/bin/steam-rom-manager" "$@"

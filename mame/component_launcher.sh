#!/bin/bash

RD_MODULES="/app/retrodeck/components"

LD_LIBRARY_PATH="$RD_MODULES/mame/lib:${LD_LIBRARY_PATH}"

exec "$RD_MODULES/mame/bin/mame" "$@"

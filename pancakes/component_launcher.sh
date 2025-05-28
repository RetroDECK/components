#!/bin/bash

RD_MODULES="/app/retrodeck/components"

LD_LIBRARY_PATH="$RD_MODULES/pancakes/lib:${LD_LIBRARY_PATH}"

exec "$RD_MODULES/pancakes/Ryujinx.sh" "$@"

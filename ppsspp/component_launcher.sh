#!/bin/bash

RD_MODULES="/app/retrodeck/components"

LD_LIBRARY_PATH="$RD_MODULES/ppsspp/lib:${LD_LIBRARY_PATH}"

exec "$RD_MODULES/ppsspp/bin/PPSSPPSDL" "$@"

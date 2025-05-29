#!/bin/bash

RD_MODULES="/app/retrodeck/components"

LD_LIBRARY_PATH="$RD_MODULES/es-de/lib:${LD_LIBRARY_PATH}"

exec "$RD_MODULES/es-de/bin/es-de" "$@"

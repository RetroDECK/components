#!/bin/bash

RD_MODULES="/app/retrodeck/components"

LD_LIBRARY_PATH="$RD_MODULES/vita3k/lib:${LD_LIBRARY_PATH}"
PATH="$RD_MODULES/vita3k/bin:$PATH"

exec "$RD_MODULES/vita3k/bin/Vita3K" "$@"

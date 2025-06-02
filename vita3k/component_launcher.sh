#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="vita3k"
RD_MODULES="/app/retrodeck/components"

LD_LIBRARY_PATH="$RD_MODULES/$COMPONENT_NAME/lib:${LD_LIBRARY_PATH}"
PATH="$RD_MODULES/$COMPONENT_NAME/bin:$PATH"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"

exec "$RD_MODULES/$COMPONENT_NAME/bin/Vita3K" "$@"

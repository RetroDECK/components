#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="ruffle"
RD_MODULES="/app/retrodeck/components"

log i "RetroDECK is now launching $COMPONENT_NAME"

exec "$RD_MODULES/$COMPONENT_NAME/ruffle" "$@"
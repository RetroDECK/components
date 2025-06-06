#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="retroarch"

log i "RetroDECK is now launching $COMPONENT_NAME"

exec "$rd_components/$COMPONENT_NAME/bin/retroarch" "$@"

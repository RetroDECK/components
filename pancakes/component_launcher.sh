#!/bin/bash

COMPONENT_NAME="pancakes"
RD_MODULES="/app/retrodeck/components"

LD_LIBRARY_PATH="$RD_MODULES/$COMPONENT_NAME/lib:${LD_LIBRARY_PATH}"

exec "$RD_MODULES/$COMPONENT_NAME/Ryujinx.sh" "$@"

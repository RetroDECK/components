#!/bin/bash

COMPONENT_NAME="rpcs3"
RD_MODULES="/app/retrodeck/components"

# This ensures the application can find its resources
export APPDIR="$RD_MODULES/$COMPONENT_NAME"

LD_LIBRARY_PATH="$RD_MODULES/$COMPONENT_NAME/lib:${LD_LIBRARY_PATH}"

exec "$RD_MODULES/$COMPONENT_NAME/bin/AppRun" "$@"
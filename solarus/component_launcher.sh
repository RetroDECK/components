#!/bin/bash

COMPONENT_NAME="solarus"
RD_MODULES="/app/retrodeck/components"

LD_LIBRARY_PATH="$RD_MODULES/$COMPONENT_NAME/lib:/app/retrodeck/components/shared-libs/qt-5.15/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="/app/retrodeck/components/shared-libs/qt-5.15/lib/plugins:${QT_PLUGIN_PATH}"

exec "$RD_MODULES/$COMPONENT_NAME/bin/solarus-launcher" "$@"
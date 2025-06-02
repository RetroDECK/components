#!/bin/bash

COMPONENT_NAME="es-de"
RD_MODULES="/app/retrodeck/components"
SHARED_LIBS="/app/retrodeck/components/shared-libs/qt-6.7/lib"

LD_LIBRARY_PATH="$RD_MODULES/$COMPONENT_NAME/lib:$SHARED_LIBS:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$SHARED_LIBS/plugins:${QT_PLUGIN_PATH}"

exec "$RD_MODULES/$COMPONENT_NAME/bin/es-de" "$@"

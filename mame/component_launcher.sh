#!/bin/bash

RD_MODULES="/app/retrodeck/components"

LD_LIBRARY_PATH="$RD_MODULES/mame/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="/app/retrodeck/components/shared_libs/qt-68/plugins:${QT_PLUGIN_PATH}"

exec "$RD_MODULES/mame/bin/mame" "$@"

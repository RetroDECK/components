#!/bin/bash

RD_MODULES="/app/retrodeck/components"

case "${XDG_CURRENT_DESKTOP}" in
    *GNOME*|*gnome*|*XFCE*)
        export QT_QPA_PLATFORMTHEME=gtk2
        ;;
esac

LD_LIBRARY_PATH="$RD_MODULES/dolphin/lib:/app/retrodeck/shared_libs/qt-68:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="/app/retrodeck/shared_libs/qt-68/plugins:${QT_PLUGIN_PATH}"

exec "$RD_MODULES/dolphin/bin/dolphin-emu" "$@"

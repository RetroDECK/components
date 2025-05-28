#!/bin/bash

RD_MODULES="/app/retrodeck/components"

case "${XDG_CURRENT_DESKTOP}" in
    *GNOME*|*gnome*|*XFCE*)
        export QT_QPA_PLATFORMTHEME=gtk2
        ;;
esac

LD_LIBRARY_PATH="$RD_MODULES/melonds/lib:/app/retrodeck/components/shared_libs/qt-67:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="/app/retrodeck/components/shared_libs/qt-67/plugins:${QT_PLUGIN_PATH}"

exec "$RD_MODULES/melonds/bin/melonDS" "$@"

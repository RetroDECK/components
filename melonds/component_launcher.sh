#!/bin/bash

RD_MODULES="/app/retrodeck/components"

case "${XDG_CURRENT_DESKTOP}" in
    *GNOME*|*gnome*|*XFCE*)
        export QT_QPA_PLATFORMTHEME=gtk2
        ;;
esac

LD_LIBRARY_PATH="$RD_MODULES/melonds/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$RD_MODULES/melonds/lib/plugins:${QT_PLUGIN_PATH}"

exec "$RD_MODULES/melonds/bin/melonDS" "$@"

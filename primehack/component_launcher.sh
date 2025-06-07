#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="primehack"

LD_LIBRARY_PATH="$rd_components/$COMPONENT_NAME/lib:$rd_shared_libs/qt-6.8/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$rd_shared_libs/qt-6.8/lib/plugins:${QT_PLUGIN_PATH}"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"
log d "QT plugin path is: $QT_PLUGIN_PATH"

case "${XDG_CURRENT_DESKTOP}" in
    *GNOME*|*gnome*|*XFCE*)
        export QT_QPA_PLATFORMTHEME=gtk2
        log d "QT_QPA_PLATFORMTHEME is set to: $QT_QPA_PLATFORMTHEME"
        ;;
esac

exec "$rd_components/$COMPONENT_NAME/bin/dolphin-emu" "$@"

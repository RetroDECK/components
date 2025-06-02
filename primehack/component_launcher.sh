#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="primehack"
RD_MODULES="/app/retrodeck/components"
SHARED_LIBS="/app/retrodeck/components/shared-libs/qt-6.8/lib"

LD_LIBRARY_PATH="$RD_MODULES/$COMPONENT_NAME/lib:$SHARED_LIBS:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$SHARED_LIBS/plugins:${QT_PLUGIN_PATH}"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"
log d "QT plugin path is: $QT_PLUGIN_PATH"

case "${XDG_CURRENT_DESKTOP}" in
    *GNOME*|*gnome*|*XFCE*)
        export QT_QPA_PLATFORMTHEME=gtk2
        log d "QT_QPA_PLATFORMTHEME is set to: $QT_QPA_PLATFORMTHEME"
        ;;
esac

exec "$RD_MODULES/$COMPONENT_NAME/bin/dolphin-emu" "$@"

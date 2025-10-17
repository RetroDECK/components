#!/bin/bash

case "${XDG_CURRENT_DESKTOP}" in
    *GNOME*|*gnome*|*XFCE*)
        export QT_QPA_PLATFORMTHEME=gtk2
        log d "QT_QPA_PLATFORMTHEME is set to: $QT_QPA_PLATFORMTHEME"
        ;;
esac

# Workaround for Wayland on Pop!_OS Cosmic (force X11 backend)
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    export QT_QPA_PLATFORM=xcb
    log d "QT_QPA_PLATFORM is set to: $QT_QPA_PLATFORM"
fi

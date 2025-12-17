#!/bin/bash

export LD_LIBRARY_PATH="$component_path/lib:$ffmpeg_path/25.08:$rd_shared_libs:$rd_shared_libs/org.kde.Sdk/6.7/:$rd_shared_libs:$rd_shared_libs/org.kde.Platform/6.7/:$rd_shared_libs/org.gnome.Platform/49/:$rd_shared_libs/org.freedesktop.Platform/25.08/:${DEFAULT_LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$rd_shared_libs/org.kde.Platform/6.7/plugins/:${QT_PLUGIN_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="$rd_shared_libs/org.kde.Platform/6.7/plugins/platforms/:${QT_QPA_PLATFORM_PLUGIN_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "QT plugin path is: $QT_PLUGIN_PATH"

if [[ "$1" =~ "$roms_path/portmaster" ]]; then
  log i "Portmaster port script detected, launching..."
  exec "$1"
else
  log i "Opening PortMaster..."
  exec "/var/data/PortMaster/PortMaster.sh" "$@"
fi

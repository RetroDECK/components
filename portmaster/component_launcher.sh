#!/bin/bash

export LD_LIBRARY_PATH="$component_path/lib:$rd_shared_libs:$rd_shared_libs/org.gnome.Platform/49/:$ffmpeg_path/25.08:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="${QT_PLUGIN_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="${QT_QPA_PLATFORM_PLUGIN_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "QT plugin path is: $QT_PLUGIN_PATH"

if [[ "$1" =~ "$roms_path/portmaster" ]]; then
  log i "Portmaster port script detected, launching..."
  if [[ ! -x "$1" ]]; then
    log w "Portmaster script $1 is not executable, repairing..."
    chmod +x "$1"
  fi
  exec "$1"
else
  log i "Opening PortMaster..."
  exec "/var/data/PortMaster/PortMaster.sh" "$@"
fi

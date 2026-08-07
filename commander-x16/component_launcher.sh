#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

HOME=/var/config/commander-x16

export LD_LIBRARY_PATH="$component_path/lib:$rd_shared_libs:${DEFAULT_LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "QT plugin path is: $QT_PLUGIN_PATH"
log d "QT QPA PLATFORM plugin path is: $QT_QPA_PLATFORM_PLUGIN_PATH"

# Launch
exec "$component_path/x16emu" -fullscreen -scale 2 -quality best -widescreen -ram 2048 -joy1 -rtc -abufs 32 -fsroot /var/config/commander-x16/system -startin /var/config/commander-x16/system "$@"


# -fullscreen -scale 2 -quality best -widescreen -ram 2048 -joy1 -rtc -abufs 32 -fsroot /var/config/commander-x16/system -startin /var/config/commander-x16/system -prg -run "$@"


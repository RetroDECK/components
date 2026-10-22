#!/bin/bash

source /app/libexec/launcher_functions.sh

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

HOME=/var/config/simcoupe

export LD_LIBRARY_PATH="$component_path/lib:$ffmpeg_path/25.08:$rd_shared_libs:$rd_shared_libs/org.kde.Platform/6.10/:$rd_shared_libs/org.gnome.Platform/49/:$rd_shared_libs/org.freedesktop.Platform/25.08/:${DEFAULT_LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $component_path"

exec "$component_path/simcoupe" -fullscreen 1 -tvaspect 1 -joytype1 1 -joytype2 2 -inpath /var/config/simcoupe/input -outpath /var/config/simcoupe/output -respath /var/config/simcoupe/resources -printerdev /var/config/simcoupe/printer "$@"


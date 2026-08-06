#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

export LD_LIBRARY_PATH="$component_path/lib:$rd_shared_libs:${DEFAULT_LD_LIBRARY_PATH}"

HOME=/var/config/kegs

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "AppDir is: $component_path"

exec "$component_path/xkegs" -audio 1 -arate 44100 -skip 0 -fullscreen 1 -dhr140 -cfg /var/config/kegs/config.kegs -rom /var/config/kegs/bios/ROM.ROM "$@"

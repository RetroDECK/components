#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

export LD_LIBRARY_PATH="$component_path/lib:$rd_shared_libs:${DEFAULT_LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"
log d "QT plugin path is: $QT_PLUGIN_PATH"
log d "QT QPA PLATFORM plugin path is: $QT_QPA_PLATFORM_PLUGIN_PATH"

# Launch
log i "RetroDECK ECWolf Runner"
path="${@: -1}" # getting the last argument as game path
args="${@:1:$#-1}" # getting all the other passed args
cd "$path"
log i "Running from $path"

# Logging args
if [ ! -v $args ]; then
    log i "With args: $args"
fi

exec "$component_path/bin/ecwolf" --fullscreen --nowait --config /var/config/ecwolf/ecwolf_rd.cfg --savedir /var/data/ecwolf/saves $args
cd -

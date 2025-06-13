#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ ("$action" == "reset") || ("$action" == "postmove") ]]; then
    if [[ -d "$roms_folder/pico8" ]]; then
        dir_prep "$roms_folder/pico8" "$bios_folder/pico-8/carts" # Symlink default game location to RD roms for cleanliness (this location is overridden anyway by the --root_path launch argument anyway)
    fi
    dir_prep "$bios_folder/pico-8" "$HOME/.lexaloffle/pico-8" # Store binary and config files together. The .lexaloffle directory is a hard-coded location for the PICO-8 config file, cannot be changed
    dir_prep "$saves_folder/pico-8" "$bios_folder/pico-8/cdata"  # PICO-8 saves folder
    cp -fv "$config/pico-8/config.txt" "$bios_folder/pico-8/config.txt"
    cp -fv "$config/pico-8/sdl_controllers.txt" "$bios_folder/pico-8/sdl_controllers.txt"
fi

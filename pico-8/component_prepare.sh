#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

if [[ ("$action" == "reset") || ("$action" == "postmove") ]]; then
    if [[ -d "$rd_home_roms_path/pico8" ]]; then
        dir_prep "$rd_home_roms_path/pico8" "$rd_home_bios_path/pico-8/carts" # Symlink default game location to RD roms for cleanliness (this location is overridden anyway by the --root_path launch argument anyway)
    fi
    dir_prep "$rd_home_bios_path/pico-8" "$HOME/.lexaloffle/pico-8" # Store binary and config files together. The .lexaloffle directory is a hard-coded location for the PICO-8 config file, cannot be changed
    dir_prep "$rd_home_saves_path/pico-8" "$rd_home_bios_path/pico-8/cdata"  # PICO-8 saves folder
    cp -fv "$config/config.txt" "$rd_home_bios_path/pico-8/config.txt"
    cp -fv "$config/sdl_controllers.txt" "$rd_home_bios_path/pico-8/sdl_controllers.txt"
fi

fi

#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ ("$action" == "reset") || ("$action" == "postmove") ]]; then
  log i "----------------------"
  log i "Resetting/post-moving $component_name"
  log i "----------------------"

  if [[ -d "$roms_path/pico8" ]]; then
    dir_prep "$roms_path/pico8" "$bios_path/pico-8/carts" # Symlink default game location to RD roms for cleanliness (this location is overridden anyway by the --root_path launch argument anyway)
  fi
  dir_prep "$bios_path/pico-8" "$HOME/.lexaloffle/pico-8" # Store binary and config files together. The .lexaloffle directory is a hard-coded location for the PICO-8 config file, cannot be changed
  dir_prep "$saves_path/pico-8" "$bios_path/pico-8/cdata"  # PICO-8 saves folder
  create_dir "$XDG_CONFIG_HOME/pico-8/"
  cp -fv "$component_config/config.txt" "$pico8_config"
  cp -fv "$component_config/sdl_controllers.txt" "$pico8_config_sdl_controllers"
fi

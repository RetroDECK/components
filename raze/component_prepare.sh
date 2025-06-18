#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

  create_dir "$XDG_CONFIG_HOME/raze"
  create_dir "$XDG_DATA_HOME/raze/audio/soundfonts"
  create_dir "$bios_path/raze"

  cp -fvr "$component_config/"raze.ini" "$XDG_CONFIG_HOME/raze"

  sed -i "s#RETRODECKHOMEDIR#${rd_home_path}#g" "$XDG_CONFIG_HOME/raze/raze.ini" # This is an unfortunate one-off because set_setting_value does not currently support JSON
  sed -i "s#RETRODECKROMSDIR#${roms_path}#g" "$XDG_CONFIG_HOME/raze/raze.ini" # This is an unfortunate one-off because set_setting_value does not currently support JSON
  sed -i "s#RETRODECKSAVESDIR#${saves_path}#g" "$XDG_CONFIG_HOME/raze/raze.ini" # This is an unfortunate one-off because set_setting_value does not currently support JSON
fi

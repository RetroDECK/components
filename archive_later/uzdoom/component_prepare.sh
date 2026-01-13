#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  # TODO: do a proper script
  # This is just a placeholder script to test the emulator's flow
  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

  create_dir "$XDG_CONFIG_HOME/uzdoom"
  create_dir "$XDG_DATA_HOME/uzdoom/audio/midi"
  create_dir "$XDG_DATA_HOME/uzdoom/audio/fm_banks"
  create_dir "$XDG_DATA_HOME/uzdoom/audio/soundfonts"
  create_dir "$bios_path/uzdoom"
  create_dir "$storage_path/doom/uzdoom/audio/soundfonts"
  create_dir "$storage_path/doom/uzdoom/audio/fm_banks"
  create_dir "$storage_path/doom/uzdoom/audio/midi"

  cp -fv "$component_config/uzdoom.ini" "$uzdoom_config"

  # This is an unfortunate one-off because set_setting_value does not currently support multiple setting names with the same name in the same section
  sed -i "s#RETRODECKHOMEDIR#${rd_home_path}#g" "$uzdoom_config"
  sed -i "s#RETRODECKROMSDIR#${roms_path}#g" "$uzdoom_config"
  sed -i "s#RETRODECKSAVESDIR#${saves_path}#g" "$uzdoom_config"
  sed -i "s#RETRODECKSBIOSSDIR#${bios_path}#g" "$uzdoom_config"
  sed -i "s#RETRODECKSTORAGESDIR#${storage_path}#g" "$uzdoom_config"
fi

#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

# TODO: do a proper script
# This is just a placeholder script to test the emulator's flow
log i "----------------------"
log i "Preparing $component_name"
log i "----------------------"

create_dir "$XDG_CONFIG_HOME/gzdoom"
create_dir "$XDG_DATA_HOME/gzdoom/audio/midi"
create_dir "$XDG_DATA_HOME/gzdoom/audio/fm_banks"
create_dir "$XDG_DATA_HOME/gzdoom/audio/soundfonts"
create_dir "$rd_home_bios_path/gzdoom"
create_dir "$rd_home_storage_path/gzdoom/audio/soundfonts"
create_dir "$rd_home_storage_path/gzdoom/audio/fm_banks"

cp -fvr "$config/"gzdoom.ini" "$XDG_CONFIG_HOME/gzdoom"

sed -i "s#RETRODECKHOMEDIR#${rd_home_path}#g" "$XDG_CONFIG_HOME/gzdoom/gzdoom.ini" # This is an unfortunate one-off because set_setting_value does not currently support JSON
sed -i "s#RETRODECKROMSDIR#${rd_home_roms_path}#g" "$XDG_CONFIG_HOME/gzdoom/gzdoom.ini" # This is an unfortunate one-off because set_setting_value does not currently support JSON
sed -i "s#RETRODECKSAVESDIR#${rd_home_saves_path}#g" "$XDG_CONFIG_HOME/gzdoom/gzdoom.ini" # This is an unfortunate one-off because set_setting_value does not currently support JSON

#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

# TODO: do a proper script
# This is just a placeholder script to test the emulator's flow
log i "----------------------"
log i "Prepearing GZDOOM"
log i "----------------------"

create_dir "$XDG_CONFIG_HOME/gzdoom"
create_dir "$XDG_DATA_HOME/gzdoom/audio/midi"
create_dir "$XDG_DATA_HOME/gzdoom/audio/fm_banks"
create_dir "$XDG_DATA_HOME/gzdoom/audio/soundfonts"
create_dir "$bios_folder/gzdoom"

cp -fvr "$config/"gzdoom.ini" "$XDG_CONFIG_HOME/gzdoom"

sed -i "s#RETRODECKHOMEDIR#${rdhome}#g" "$XDG_CONFIG_HOME/gzdoom/gzdoom.ini" # This is an unfortunate one-off because set_setting_value does not currently support JSON
sed -i "s#RETRODECKROMSDIR#${roms_folder}#g" "$XDG_CONFIG_HOME/gzdoom/gzdoom.ini" # This is an unfortunate one-off because set_setting_value does not currently support JSON
sed -i "s#RETRODECKSAVESDIR#${saves_folder}#g" "$XDG_CONFIG_HOME/gzdoom/gzdoom.ini" # This is an unfortunate one-off because set_setting_value does not currently support JSON

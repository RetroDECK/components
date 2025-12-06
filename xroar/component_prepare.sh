#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

  create_dir -d "$XDG_CONFIG_HOME/xroar"
  cp -f "$component_config/xroar.conf" "$xroar_config" && log i "Copied default xroar.conf to $xroar_config"
  sed -i "s#RETRODECKROMSDIR#${roms_path}#g" "$xroar_config" && log i "Set ROMs directory in xroar.conf"
  sed -i "s#RETRODECKBIOSDIR#${bios_path}#g" "$xroar_config" && log i "Set BIOS directory in xroar.conf"

# XRoar does not provide a default directory for state files in the config, so you must choose a folder each time you save or load.

  create_dir "$states_path/xroar/coco/"
  create_dir "$states_path/xroar/dragon32/"
  create_dir "$states_path/xroar/tanodragon/"

fi

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

fi

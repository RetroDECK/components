#!bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

  rm -rf "$XDG_DATA_HOME/PortMaster"
  unzip "/app/retrodeck/components/portmaster/PortMaster.zip" -d "$XDG_DATA_HOME/"
  cp -f "$XDG_DATA_HOME/PortMaster/retrodeck/PortMaster.txt" "$XDG_DATA_HOME/PortMaster/PortMaster.sh"
  chmod +x "$XDG_DATA_HOME/PortMaster/PortMaster.sh"
  rm -f "$roms_path/portmaster/PortMaster.sh"
  install -Dm755 "$XDG_DATA_HOME/PortMaster/PortMaster.sh" "$roms_path/portmaster/PortMaster.sh"
  create_dir "$XDG_DATA_HOME/PortMaster/config/"
  cp "$component_config/config.json" "$XDG_DATA_HOME/PortMaster/config/config.json"
fi

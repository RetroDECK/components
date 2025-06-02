#!bin/bash

if [[ "$component" =~ ^(portmaster|all)$ ]]; then
    component_found="true"
      # TODO: MultiUser
      log i "----------------------"
      log i "Prepearing PortMaster"
      log i "----------------------"

      rm -rf "$XDG_DATA_HOME/PortMaster"
      unzip "/app/retrodeck/components/portmaster/PortMaster.zip" -d "$XDG_DATA_HOME/"
      cp -f "$XDG_DATA_HOME/PortMaster/retrodeck/PortMaster.txt" "$XDG_DATA_HOME/PortMaster/PortMaster.sh"
      chmod +x "$XDG_DATA_HOME/PortMaster/PortMaster.sh"
      rm -f "$roms_folder/portmaster/PortMaster.sh"
      install -Dm755 "$XDG_DATA_HOME/PortMaster/PortMaster.sh" "$roms_folder/portmaster/PortMaster.sh"
      create_dir "$XDG_DATA_HOME/PortMaster/config/"
      cp "$config/portmaster/config.json" "$XDG_DATA_HOME/PortMaster/config/config.json"

fi
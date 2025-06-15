#!bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

# TODO: MultiUser
log i "----------------------"
log i "Prepearing PortMaster"
log i "----------------------"

rm -rf "$XDG_DATA_HOME/PortMaster"
unzip "/app/retrodeck/components/portmaster/PortMaster.zip" -d "$XDG_DATA_HOME/"
cp -f "$XDG_DATA_HOME/PortMaster/retrodeck/PortMaster.txt" "$XDG_DATA_HOME/PortMaster/PortMaster.sh"
chmod +x "$XDG_DATA_HOME/PortMaster/PortMaster.sh"
rm -f "$rd_home_roms_path/portmaster/PortMaster.sh"
install -Dm755 "$XDG_DATA_HOME/PortMaster/PortMaster.sh" "$rd_home_roms_path/portmaster/PortMaster.sh"
create_dir "$XDG_DATA_HOME/PortMaster/config/"
cp "$config/config.json" "$XDG_DATA_HOME/PortMaster/config/config.json"

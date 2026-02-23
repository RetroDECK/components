#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

  dir_prep "$saves_path/ecwolf" "$ecwolf_saves_path"
  create_dir "$ecwolf_saves_path/wl6"
  create_dir "$ecwolf_saves_path/wl1"
  create_dir "$ecwolf_saves_path/sod"
  create_dir "$ecwolf_saves_path/sdm"
  create_dir "$ecwolf_saves_path/sd1"
  create_dir "$ecwolf_saves_path/sd2"
  create_dir "$ecwolf_saves_path/sd3"
  create_dir "$ecwolf_saves_path/n3d"

  create_dir "$roms_path/wolf/Wolfenstein 3D - Full.wolf"
  create_dir "$roms_path/wolf/Wolfenstein 3D - Shareware.wolf"
  create_dir "$roms_path/wolf/Spear of Destiny - Full.wolf"
  create_dir "$roms_path/wolf/Spear of Destiny - Demo.wolf"
  create_dir "$roms_path/wolf/Spear of Destiny - Mission Pack 1.wolf"
  create_dir "$roms_path/wolf/Spear of Destiny - Mission Pack 2.wolf"
  create_dir "$roms_path/wolf/Spear of Destiny - Mission Pack 3.wolf"
  create_dir "$roms_path/wolf/Super 3D Noahs Ark.wolf"

fi

if [[ "$action" == "postmove" ]]; then # Run commands that apply to both resets and moves
  log i "----------------------"
  log i "Post-moving $component_name"
  log i "----------------------"

  dir_prep "$saves_path/ecwolf" "$ecwolf_saves_path"
  
  create_dir "$roms_path/wolf/Wolfenstein 3D - Full.wolf"
  create_dir "$roms_path/wolf/Wolfenstein 3D - Shareware.wolf"
  create_dir "$roms_path/wolf/Spear of Destiny - Full.wolf"
  create_dir "$roms_path/wolf/Spear of Destiny - Demo.wolf"
  create_dir "$roms_path/wolf/Spear of Destiny - Mission Pack 1.wolf"
  create_dir "$roms_path/wolf/Spear of Destiny - Mission Pack 2.wolf"
  create_dir "$roms_path/wolf/Spear of Destiny - Mission Pack 3.wolf"
  create_dir "$roms_path/wolf/Super 3D Noahs Ark.wolf"
fi

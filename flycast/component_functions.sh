#!/bin/bash

flycast_config="$XDG_CONFIG_HOME/flycast/emu.cfg"

# Todo
# Dreamcast.AutoLoadState = no, Dreamcast.AutoSaveState = no | add to autoresume
# rend.WideScreen = no, rend.WidescreenGameHacks = no | add to widescreen
# [achievements]
# Enabled = no
# HardcoreMode = no
# Token = 
# UserName = 

_prepare_component::flycast() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Flycast"
      log i "----------------------"


    create_dir -d "$XDG_CONFIG_HOME/flycast/mappings"      
    create_dir -d "$XDG_DATA_HOME/flycast/"

    cp -fvr "$component_config/"* "$XDG_CONFIG_HOME/flycast/"

    create_dir -d "$storage_path/Flycast/boxart"

    create_dir -d "$cheats_path/Flycast/cheats"

    create_dir -d "$saves_path/dreamcast/Flycast/saves"
    create_dir -d "$saves_path/dreamcast/Flycast/VMU"

    create_dir -d "$states_path/dreamcast/Flycast/"

    create_dir -d "$texture_path/Flycast/Textures"
    create_dir -d "$texture_path/Flycast/TextureDump"

    sed -i "s|^Dreamcast.BiosPath = .*|Dreamcast.BiosPath = $bios_path|" $flycast_config

    sed -i "s|^Dreamcast.BoxartPath = .*|Dreamcast.BoxartPath = $storage_path/Flycast/boxart|" $flycast_config  
  
    sed -i "s|^Dreamcast.CheatPath = .*|Dreamcast.CheatPath = $cheats_path/Flycast/cheats|" $flycast_config
    
    sed -i "s|^Dreamcast.ContentPath = .*|Dreamcast.ContentPath = $roms_path/dreamcast|" $flycast_config

    sed -i "s|^Dreamcast.SavePath = .*|Dreamcast.SavePath = $saves_path/dreamcast/Flycast/saves|" $flycast_config
    sed -i "s|^Dreamcast.VMUPath = .*|Dreamcast.VMUPath = $saves_path/dreamcast/Flycast/VMU|" $flycast_config

    sed -i "s|^Dreamcast.SavestatePath = .*|Dreamcast.SavestatePath = $states_path/dreamcast/Flycast|" $flycast_config

    sed -i "s|^Dreamcast.TextureDumpPath = .*|Dreamcast.TextureDumpPath = $textures_path/Flycast/TextureDump|" $flycast_config
    sed -i "s|^Dreamcast.TexturePath = .*|Dreamcast.TextureDumpPath = $textures_path/Flycast/Textures|" $flycast_config

    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving Flycast"
      log i "----------------------"

    sed -i "s|^Dreamcast.BiosPath = .*|Dreamcast.BiosPath = $bios_path|" $flycast_config

    sed -i "s|^Dreamcast.BoxartPath = .*|Dreamcast.BoxartPath = $storage_path/Flycast/boxart|" $flycast_config  
  
    sed -i "s|^Dreamcast.CheatPath = .*|Dreamcast.CheatPath = $cheats_path/Flycast/cheats|" $flycast_config
    
    sed -i "s|^Dreamcast.ContentPath = .*|Dreamcast.ContentPath = $roms_path/dreamcast|" $flycast_config

    sed -i "s|^Dreamcast.SavePath = .*|Dreamcast.SavePath = $saves_path/dreamcast/Flycast/saves|" $flycast_config
    sed -i "s|^Dreamcast.VMUPath = .*|Dreamcast.VMUPath = $saves_path/dreamcast/Flycast/VMU|" $flycast_config

    sed -i "s|^Dreamcast.SavestatePath = .*|Dreamcast.SavestatePath = $states_path/dreamcast/Flycast|" $flycast_config

    sed -i "s|^Dreamcast.TextureDumpPath = .*|Dreamcast.TextureDumpPath = $textures_path/Flycast/TextureDump|" $flycast_config
    sed -i "s|^Dreamcast.TexturePath = .*|Dreamcast.TextureDumpPath = $textures_path/Flycast/Textures|" $flycast_config


    ;;
    
  esac

}
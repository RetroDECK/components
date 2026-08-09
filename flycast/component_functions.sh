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

    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving Flycast"
      log i "----------------------"


    ;;
    
  esac

}
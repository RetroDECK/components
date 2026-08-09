#!/bin/bash

flycast_config="$XDG_CONFIG_HOME/flycast/emu.cfg"

# Dreamcast.AutoLoadState = no, Dreamcast.AutoSaveState = no | add to autoresume
# rend.WideScreen = no, rend.WidescreenGameHacks = no | add to widescreen

_prepare_component::flycast() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Flycast"
      log i "----------------------"


    create_dir -d "$XDG_CONFIG_HOME/flycast/"      
    create_dir -d "$XDG_DATA_HOME/flycast/"
    cp -fvr "$component_config/"* "$XDG_CONFIG_HOME/flycast/"

    dir_prep "$texture_packs_path/Flycast/TEXDUMP" "$XDG_CONFIG_HOME/flycast/TEXDUMP"
    dir_prep "$texture_packs_path/Flycast/TEXTURES" "$XDG_CONFIG_HOME/flycast/TEXTURES"

    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving Flycast"
      log i "----------------------"

    dir_prep "$texture_packs_path/Flycast/TEXDUMP" "$XDG_CONFIG_HOME/flycast/TEXDUMP"
    dir_prep "$texture_packs_path/Flycast/TEXTURES" "$XDG_CONFIG_HOME/flycast/TEXTURES"

    ;;
    
  esac

}
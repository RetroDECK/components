#!/bin/bash

_prepare_component::zesarux() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Zesarux"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/zesarux/"
      create_dir -d "$XDG_DATA_HOME/zesarux/esxdos"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/zesarux"

      dir_prep "$storage_path/Zesarux/esxdos"  "$XDG_DATA_HOME/zesarux/esxdos"
      
    ;;


    postmove)
      log i "------------------------"
      log i "Post-moving Zesarux"
      log i "------------------------"

      dir_prep "$storage_path/Zesarux/esxdos"  "$XDG_DATA_HOME/zesarux/esxdos"

    ;;

  esac
}



#!/bin/bash

amiberry_config="$XDG_CONFIG_HOME/amiberry/amiberry.conf"

_prepare_component::amiberry() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Amiberry"
      log i "----------------------"

        cp -fvr "$component_config/"* "$XDG_CONFIG_HOME/amiberry/"


      
    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving Amiberry"
      log i "----------------------"


    ;;
    
  esac
}

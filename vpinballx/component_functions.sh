#!/bin/bash

export vpinballx_config="$XDG_CONFIG_HOME/vpinballx/VPinballX.ini"


_prepare_component::vpinballx() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Visual Pinball X"
      log i "----------------------"

      create_dir "$XDG_CONFIG_HOME/vpinballx/.vpinball/user"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/vpinballx/.vpinball"
      

    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving Visual Pinball X"
      log i "----------------------"


    ;;
    
  esac
}
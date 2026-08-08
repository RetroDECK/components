#!/bin/bash

scummvm_config="$XDG_CONFIG_HOME/scummvm/scummvm.ini"

_prepare_component::scummvm() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting ScummVM"
      log i "----------------------"

        cp -fvr "$component_config/"* "$XDG_CONFIG_HOME/scummvm/"

    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving ScummVM"
      log i "----------------------"

    ;;
    
  esac
}
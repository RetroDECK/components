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
      
    ;;

  esac
}



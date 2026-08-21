#!/bin/bash

_prepare_component::gametank() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Commander X16"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/gametank"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/gametank"

    ;;

  esac
  
}
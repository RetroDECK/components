#!/bin/bash

export simcoupe_config="$XDG_CONFIG_HOME/simcoupe/SimCoupe.cfg"

_prepare_component::simcoupe() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting SimCoupé"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/simcoupe/"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/simcoupe/"

    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving SimCoupé"
      log i "----------------------"

  esac
}
#!/bin/bash

export tsugaru_config="$XDG_CONFIG_HOME/tsugaru/"

_prepare_component::tsugaru() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Tsugaru"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/tsugaru"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/tsugaru"

    ;;

  esac
}
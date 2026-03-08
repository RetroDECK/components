#!/bin/bash

_prepare_component::solarus() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting Solarus"
      log i "------------------------"

      create_dir "$XDG_CONFIG_HOME/solarus"
    ;;

  esac
}
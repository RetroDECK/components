#!/bin/bash

_prepare_component::rtdink() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting RTDink"
      log i "----------------------"

        create_dir "$XDG_CONFIG_HOME/rtdink"

    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving RTDink"
      log i "------------------------"


    ;;

  esac
}


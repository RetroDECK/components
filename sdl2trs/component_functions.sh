#!/bin/bash

_prepare_component::sdl2trs() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting SDL2TRS"
      log i "----------------------"

    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving SDL2TRS"
      log i "----------------------"
      

  esac
}

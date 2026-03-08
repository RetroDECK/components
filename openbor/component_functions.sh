#!/bin/bash

_prepare_component::openbor() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting OpenBOR"
      log i "------------------------"
    ;;

  esac
}

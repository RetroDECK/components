#!/bin/bash

# Supermodel all config folders and files needs to be next to the roms.

export supermodel_config="$roms_path/model3/Config/Supermodel.ini"

_prepare_component::supermodel() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Supermodel"
      log i "----------------------"

      cp -fr "$component_config/"* "$roms_path/model3/"

    ;;

  esac
}
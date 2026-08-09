#!/bin/bash

export supermodel_config="$XDG_CONFIG_HOME/supermodel/Config/Supermodel.ini"

_prepare_component::supermodel() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Supermodel"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/supermodel/"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/supermodel/"

    ;;

  esac
}
#!/bin/bash

_prepare_component::mvem() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting MVEM"
      log i "------------------------"

      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/mvem/"
    ;;
#!/bin/bash

_prepare_component::raofflineproxy() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting RAOfflineProxy"
      log i "----------------------"

  # raofflineproxy resolves its config dir from XDG_CONFIG_HOME and its API
  # response cache from XDG_CACHE_HOME at startup (falling back to
  # ~/.config/raofflineproxy and ~/.cache/raofflineproxy), so just make sure
  # both exist ahead of first launch.
  
  create_dir "$XDG_CONFIG_HOME/raofflineproxy"
  create_dir "$XDG_CACHE_HOME/raofflineproxy"
    ;;

  esac
}
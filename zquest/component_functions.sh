#!/bin/bash

export zquest_config="$XDG_CONFIG_HOME/zquest/zc.cfg"

_prepare_component::zquest() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting ZQuest Classic"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/zquest"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/zquest"

      dir_prep "$saves_path/ZQuest-SA/saves" "$XDG_DATA_HOME/zquest/saves"

    ;;

    postmove)
          log i "----------------------"
          log i "Post-moving ZQuest Classic"
          log i "----------------------"

      dir_prep "$saves_path/ZQuest-SA/saves" "$XDG_DATA_HOME/zquest/saves"

    ;;

  esac
}

_post_update::zquest() {
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.11.0"; then
    log i "0.11.0 ZQuest Classic Setup"

    prepare_component "reset" "zquest"
  fi
}
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

_post_update::solarus() {
  local previous_version="$1"

}

_post_update_legacy::solarus() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.10.0b"; then
    # In version 0.10.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
    # - Init Solarus as it is a new emulator
    
    log i "0.10.0b Upgrade - Reset: Solarus"
    prepare_component "reset" "solarus"
  fi
}

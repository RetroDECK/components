#!/bin/bash

export xenia_edge_config="$XDG_CONFIG_HOME/Xenia/xenia-edge.config.toml"

## Xenia Edge uses Xenia as directory name and default writes into $XDG_DATA_HOME/Xenia

_prepare_component::xenia-edge() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Xenia Edge"
      log i "----------------------"

      create_dir -d "$XDG_DATA_HOME/Xenia"
      cp -fr "$component_config/"* "$XDG_DATA_HOME/Xenia"
      dir_prep "$storage_path/Xenia-Edge/cache" "$XDG_DATA_HOME/Xenia/cache"
      dir_prep "$storage_path/Xenia-Edge/cache0" "$XDG_DATA_HOME/Xenia/cache0"
      dir_prep "$storage_path/Xenia-Edge/cache1" "$XDG_DATA_HOME/Xenia/cache1"
      dir_prep "$storage_path/Xenia-Edge/library" "$XDG_DATA_HOME/Xenia/library"

      dir_prep "$saves_path/Xenia-Edge-SA/content" "$XDG_DATA_HOME/Xenia/content"

      dir_prep "$mods_path/Xenia-Edge/plugins" "$XDG_DATA_HOME/Xenia/plugins"
      dir_prep "$mods_path/Xenia-Edge/patches" "$XDG_DATA_HOME/Xenia/patches"

    ;;


    postmove)
      log i "------------------------"
      log i "Post-moving Xenia Edge"
      log i "------------------------"

      dir_prep "$storage_path/Xenia-Edge/cache" "$XDG_DATA_HOME/Xenia/cache"
      dir_prep "$storage_path/Xenia-Edge/cache0" "$XDG_DATA_HOME/Xenia/cache0"
      dir_prep "$storage_path/Xenia-Edge/cache1" "$XDG_DATA_HOME/Xenia/cache1"
      dir_prep "$storage_path/Xenia-Edge/library" "$XDG_DATA_HOME/Xenia/library"

      dir_prep "$saves_path/Xenia-Edge-SA/content" "$XDG_DATA_HOME/Xenia/content"

      dir_prep "$mods_path/Xenia-Edge/plugins" "$XDG_DATA_HOME/Xenia/plugins"
      dir_prep "$mods_path/Xenia-Edge/patches" "$XDG_DATA_HOME/Xenia/patches"
      
    ;;

  esac
}

_post_update::xenia-edge() {
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.11.0"; then
    log i "0.11.0 Xenia Edge Setup"

    prepare_component "reset" "xenia-edge"
  fi
}
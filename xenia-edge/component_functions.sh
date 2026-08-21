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
      dir_prep "$storage_path/Xenia/cache" "$XDG_DATA_HOME/Xenia/cache"
      dir_prep "$storage_path/Xenia/cache0" "$XDG_DATA_HOME/Xenia/cache0"
      dir_prep "$storage_path/Xenia/cache1" "$XDG_DATA_HOME/Xenia/cache1"
      dir_prep "$storage_path/Xenia/library" "$XDG_DATA_HOME/Xenia/library"

      dir_prep "$saves_path/xbox360/Xenia/content" "$XDG_DATA_HOME/Xenia/content"

      dir_prep "$mods_path/Xenia/plugins" "$XDG_DATA_HOME/Xenia/plugins"

    ;;


    postmove)
      log i "------------------------"
      log i "Post-moving Xenia Edge"
      log i "------------------------"

      dir_prep "$storage_path/Xenia/cache" "$XDG_DATA_HOME/Xenia/cache"
      dir_prep "$storage_path/Xenia/cache0" "$XDG_DATA_HOME/Xenia/cache0"
      dir_prep "$storage_path/Xenia/cache1" "$XDG_DATA_HOME/Xenia/cache1"
      dir_prep "$storage_path/Xenia/library" "$XDG_DATA_HOME/Xenia/library"

      dir_prep "$saves_path/xbox360/Xenia/content" "$XDG_DATA_HOME/Xenia/content"

      dir_prep "$mods_path/Xenia/plugins" "$XDG_DATA_HOME/Xenia/plugins"
      
    ;;

  esac
}
#!/bin/bash

gargoyle_config="$XDG_CONFIG_HOME/gargoyle/garglk.ini"

_prepare_component::gargoyle() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Gargoyle"
      log i "----------------------"

      create_dir "$XDG_CONFIG_HOME/gargoyle"
      create_dir "$XDG_DATA_HOME/gargoyle"
      dir_prep "$storage_path/gargoyle/themes" "$XDG_DATA_HOME/gargoyle/themes"
      dir_prep "$saves_path/if/gargoyle/gamedata" "$XDG_DATA_HOME/gargoyle/gamedata"

    ;;

      postmove)
      log i "------------------------"
      log i "Post-moving Gargoyle"
      log i "------------------------"

      dir_prep "$storage_path/gargoyle/themes" "$XDG_DATA_HOME/gargoyle/themes"
      dir_prep "$saves_path/if/gargoyle/gamedata" "$XDG_DATA_HOME/gargoyle/gamedata"
    ;;

  esac

}


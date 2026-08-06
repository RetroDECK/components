#!/bin/bash

#!/bin/bash

export kegs_config="$XDG_CONFIG_HOME/kegs/config.kegs"

_prepare_component::tsugaru() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting KEGS"
      log i "----------------------"

      create_dir "$XDG_CONFIG_HOME/kegs"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/kegs"
      dir_prep "$bios_path" "$XDG_CONFIG_HOME/kegs/bios"

    ;;

    postmove)
          log i "----------------------"
          log i "Post-moving KEGS"
          log i "----------------------"

        dir_prep "$bios_path" "$XDG_CONFIG_HOME/kegs/bios"

    ;;

  esac
}
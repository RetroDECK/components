#!/bin/bash

shadps4_config="$XDG_CONFIG_HOME/shadps4/config.toml"
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"


_prepare_component::shadps4() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
        log i "--------------------"
        log i "Preparing SHADPS4"
        log i "--------------------"

        create_dir "$storage_path/ps4/shadps4/installed"
        create_dir "$storage_path/ps4/shadps4/addcont"
        set_setting_value "$shadps4_config" "installDirs" "$storage_path/ps4/installed" "shadps4"
        set_setting_value "$shadps4_config" "addonInstallDir" "$storage_path/ps4/addcont" "shadps4"
        set_setting_value "$shadps4_config" "saveDataPath" "$saves_path/ps4/shadps4" "shadps4"
    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving SHADPS4"
      log i "------------------------"

      echo "TBD"
    ;;

    startup)
      echo "TBD"
    ;;

  esac
}
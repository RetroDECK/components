#!/bin/bash

# Supermodel needs to point at the config folders from roms

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
      dir_prep "$XDG_CONFIG_HOME/supermodel/NVRAM" "$roms_path/model3/NVRAM"
      dir_prep "$XDG_CONFIG_HOME/supermodel/Config" "$roms_path/model3/Config"
      dir_prep "$XDG_CONFIG_HOME/supermodel/Assets" "$roms_path/model3/Assets"
      dir_prep "$logs_path/supermodel/Analysis" "$roms_path/model3/Analysis"
      dir_prep "$logs_path/supermodel/Logs" "$roms_path/model3/Logs"
      dir_prep "$saves_path/model3/supermodel/Saves" "$roms_path/model3/Saves"

    ;;

    postmove)
          log i "----------------------"
          log i "Post-moving Supermodel"
          log i "----------------------"

      dir_prep "$XDG_CONFIG_HOME/supermodel/NVRAM" "$roms_path/model3/NVRAM"
      dir_prep "$XDG_CONFIG_HOME/supermodel/Config" "$roms_path/model3/Config"
      dir_prep "$XDG_CONFIG_HOME/supermodel/Assets" "$roms_path/model3/Assets"
      dir_prep "$logs_path/supermodel/Analysis" "$roms_path/model3/Analysis"
      dir_prep "$logs_path/supermodel/Logs" "$roms_path/model3/Logs"
      dir_prep "$saves_path/model3/supermodel/Saves" "$roms_path/model3/Saves"

    ;;

  esac
}
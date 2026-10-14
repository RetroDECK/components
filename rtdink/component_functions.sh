#!/bin/bash

_prepare_component::rtdink() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting RTDink"
      log i "----------------------"

      dir_prep "$roms_path/dink" "$XDG_DATA_HOME/rtdink/dmods"
      
      # This is just the adapted dink-smallwood-hd.sh for RetroDECK Paths

      DATA_DIR="$XDG_DATA_HOME/rtdink"
      APP_SHARE="/app/retrodeck/components/rtdink/share/com.rtsoft.DinkSmallwoodHD"

      for dir in interface audio; do
          if [ ! -e "$DATA_DIR/$dir" ]; then
              ln -sf "$APP_SHARE/$dir" "$DATA_DIR/$dir"
          fi
      done

      mkdir -p "$DATA_DIR/dink"

      for item in "$APP_SHARE/dink/"*; do
          name=$(basename "$item")
          if [ ! -f "$DATA_DIR/dink/$name" ]; then
              ln -sfn "$item" "$DATA_DIR/dink/$name"
          fi
      done

      if [ ! -e "$DATA_DIR/RTDinkApp" ]; then
          ln -sf "/app/retrodeck/components/rtdink/bin/RTDinkApp" "$DATA_DIR/RTDinkApp"
      fi


    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving RTDink"
      log i "------------------------"

      dir_prep "$roms_path/dink" "$XDG_DATA_HOME/rtdink/dmods"

    ;;

  esac
}



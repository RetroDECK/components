#!/bin/bash

export keisho_config="$XDG_CONFIG_HOME/keisho/keisho.ini"

_prepare_component::keisho() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Keisho"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/keisho"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/keisho"

      create_dir -d "$saves_path/Keisho-SA/nvram"
      create_dir -d "$screenshots_path/keisho"

      dir_prep "$texture_packs_path/keisho/textures" "$saves_path/Keisho-SA/nvram/textures"

      sed -i "s|^rom_dir =.*|rom_dir = $roms_path/model2|" $sm2_emu_config
      sed -i "s|^nvram_dir =.*|nvram_dir = $saves_path/Keisho-SA/nvram|" $sm2_emu_config
      sed -i "s|^screenshot_dir =.*|screenshot_dir = $screenshots_path/keisho|" $sm2_emu_config

    ;;

    postmove)
          log i "----------------------"
          log i "Post-moving Keisho"
          log i "----------------------"

      dir_prep "$texture_packs_path/keisho/textures" "$saves_path/Keisho-SA/nvram/textures"

      sed -i "s|^rom_dir =.*|rom_dir = $roms_path/model2|" $sm2_emu_config
      sed -i "s|^nvram_dir =.*|nvram_dir = $saves_path/Keisho-SA/nvram|" $sm2_emu_config
      sed -i "s|^screenshot_dir =.*|screenshot_dir = $screenshots_path/keisho|" $sm2_emu_config


    ;;

  esac
}

_post_update::keisho() {
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.11.0"; then
    log i "0.11.0 keisho Setup"

    prepare_component "reset" "keisho"
  fi
}
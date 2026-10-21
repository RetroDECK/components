#!/bin/bash

export uzdoom_config="$XDG_CONFIG_HOME/uzdoom/uzdoom.ini"

_prepare_component::uzdoom() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting UZDoom"
      log i "------------------------"

      create_dir "$XDG_CONFIG_HOME/uzdoom"
      create_dir "$XDG_DATA_HOME/uzdoom/audio/midi"
      create_dir "$XDG_DATA_HOME/uzdoom/audio/fm_banks"
      create_dir "$XDG_DATA_HOME/uzdoom/audio/soundfonts"
      create_dir "$bios_path/UZDoom-SA"
      create_dir "$storage_path/UZDoom/audio/soundfonts"
      create_dir "$storage_path/UZDoom/audio/fm_banks"
      create_dir "$storage_path/UZDoom/audio/midi"
      create_dir "$saves_path/UZDoom-SA"

      cp -fv "$component_config/uzdoom.ini" "$uzdoom_config"

      # This is an unfortunate one-off because set_setting_value does not currently support multiple setting names with the same name in the same section
      sed -i "s#RETRODECKHOMEDIR#${rd_home_path}#g" "$uzdoom_config"
      sed -i "s#RETRODECKROMSDIR#${roms_path}#g" "$uzdoom_config"
      sed -i "s#RETRODECKBIOSDIR#${bios_path}#g" "$uzdoom_config"
      sed -i "s#RETRODECKSAVESDIR#${saves_path}#g" "$uzdoom_config"
      sed -i "s#RETRODECKSTORAGESDIR#${storage_path}#g" "$uzdoom_config"
    ;;

  esac
}

_post_update::uzdoom() {
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.11.0"; then
    log i "0.11.0 UZDoom Setup"

    prepare_component "reset" "uzdoom"
    cp -rfv "$saves_path/doom/gzdoom/" "$saves_path/UZDoom-SA"

    create_dir "$backups_path/0.11.0/UZDoom-SA"
    cp -rfv "$saves_path/doom/gzdoom/" "$backups_path/0.11.0/UZDoom-SA"

    create_dir "$saves_path/RetroArch"
    mv "$saves_path/doom" "$saves_path/RetroArch/"

  fi

}
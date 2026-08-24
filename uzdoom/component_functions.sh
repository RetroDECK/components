#!/bin/bash

export uzdoom_config="$XDG_CONFIG_HOME/uzdoom/uzdoom.ini"

_prepare_component::uzdoom() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting UZDOOM"
      log i "------------------------"
      
      # TODO: do a proper script
      # This is just a placeholder script to test the emulator's flow

      create_dir "$XDG_CONFIG_HOME/uzdoom"
      create_dir "$XDG_DATA_HOME/uzdoom/audio/midi"
      create_dir "$XDG_DATA_HOME/uzdoom/audio/fm_banks"
      create_dir "$XDG_DATA_HOME/uzdoom/audio/soundfonts"
      create_dir "$bios_path/uzdoom"
      create_dir "$storage_path/uzdoom/audio/soundfonts"
      create_dir "$storage_path/uzdoom/audio/fm_banks"
      create_dir "$storage_path/uzdoom/audio/midi"

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

}

_download_freedoom() {
  local freedoom_tmp freedoom_url

  rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Freedoom" \
    --text="Do you want to download the latest <span foreground='$purple'><b>Freedoom</b></span> release?"

  if [ $? != 0 ]; then
    return 0
  fi

  if ! curl -fsS --connect-timeout 5 https://github.com >/dev/null; then
    rd_zenity --warning \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Freedoom" \
      --text="No internet connection was detected.<br><br>Freedoom could not be downloaded."
    return 1
  fi

  freedoom_tmp=$(mktemp -d)

  freedoom_url=$(curl -fsSL https://api.github.com/repos/freedoom/freedoom/releases/latest |
    grep -o 'https://[^"]*\.zip' | head -1)

  curl -fL --progress-bar "$freedoom_url" -o "$freedoom_tmp/freedoom.zip" &&
    unzip -qo "$freedoom_tmp/freedoom.zip" -d "$freedoom_tmp"

  find "$freedoom_tmp" -type f -iname '*.wad' -exec cp -f {} "$roms_path/doom/" \;

  rm -rf "$freedoom_tmp"

  rd_zenity --info \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Freedoom" \
    --text="The latest <span foreground='$purple'><b>Freedoom</b></span> WAD files have been downloaded successfully to $roms_path/doom/."
}

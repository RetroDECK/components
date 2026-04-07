#!/bin/bash

retrodeck_api_component_path="$(get_component_path "retrodeck-api")"

source "$retrodeck_api_component_path/libexec/api_server.sh"

_prepare_component::retrodeck-api() {
  local action="$1"
  shift

  local component_path="$(get_own_component_path)"

  case "$action" in

    startup)
      if [[ $(get_component_option "retrodeck-api" "rd_api_enabled") == "true" ]]; then
        retrodeck_api "start"
      fi
    ;;

    shutdown)
      if [[ $(get_component_option "retrodeck-api" "rd_api_enabled") == "true" ]]; then
        retrodeck_api "stop"
      fi
    ;;

  esac
}

configurator_rd_api_toggle_dialog() {
  if [[ $(get_component_option "retrodeck-api" "rd_api_enabled") == "true" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - API Server" \
    --text="The RetroDECK API server is currently <span foreground='$purple'><b>Enabled</b></span>. Do you want to disable it?"
    
    if [ $? == 0 ] # User clicked "Yes"
    then
      retrodeck_api "stop"
      set_component_option "retrodeck-api" "rd_api_enabled" "false"
      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - API Server" \
      --text="The RetroDECK API server is now <span foreground='$purple'><b>Disabled</b></span>."
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - API Server" \
    --text="The RetroDECK API server is currently <span foreground='$purple'><b>Disabled</b></span>. Do you want to enable it?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      retrodeck_api "start"
      set_component_option "retrodeck-api" "rd_api_enabled" "true"

      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - API Server" \
      --text="The RetroDECK API server is now <span foreground='$purple'><b>Enabled</b></span>."
    fi
  fi
}

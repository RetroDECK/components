#!/bin/bash

opensurge_surgetherabbit_toggle() {
  if [[ ! $(get_component_option "opensurge" "surge_the_rabbit_visible") == "false" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - OpenSurge Surge the Rabbit Visibility" \
    --text="OpenSurge Surge the Rabbit visibility is currently <span foreground='$purple'><b>Enabled</b></span>. Do you want to disable it?"
    
    if [ $? == 0 ] # User clicked "Yes"
    then
      remove_gamelist_entry "opensurge" "opensurge_surge_the_rabbit"
      set_component_option "opensurge" "surge_the_rabbit_visible" "false"
      
      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - OpenSurge Surge the Rabbit Visibility" \
      --text="OpenSurge Surge the Rabbit visibility is now <span foreground='$purple'><b>Disabled</b></span>."
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - OpenSurge Surge the Rabbit Visibility" \
    --text="OpenSurge Surge the Rabbit visibility is currently <span foreground='$purple'><b>Disabled</b></span>. Do you want to enable it?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      create_gamelist_entry "opensurge" "opensurge_surge_the_rabbit"
      set_component_option "opensurge" "surge_the_rabbit_visible" "true"

      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - OpenSurge Surge the Rabbit Visibility" \
      --text="OpenSurge Surge the Rabbit visibility is now <span foreground='$purple'><b>Enabled</b></span>."
    fi
  fi
}

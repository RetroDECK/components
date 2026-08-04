#!/bin/bash

opensurge_surgetherabbit_toggle() {
  local file="$roms_path/opensurge/Surge the Rabbit.surge"

  local response
  response=$(rd_zenity --question --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title="Surge the Rabbit" \
    --ok-label="Enable" \
    --cancel-label="Cancel" \
    --extra-button="Disable" \
    --text="<big><b>Surge the Rabbit in Open Surge</b></big>\n\nEnable or disable the game?")

  local rc=$?

  if [ $rc -eq 0 ]; then 
    touch "$file"
    rd_zenity --info --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title="Success" \
      --text="Surge the Rabbit has been enabled.\n\nA restart of RetroDECK is required for the game to appear." \
      --width=400
  elif [ "$response" = "Disable" ]; then
    [[ -f "$file" ]] && rm "$file"
    rd_zenity --info --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title="Success" \
      --text="Surge the Rabbit has been disabled." \
      --width=400
  fi  # 
}
#!/bin/bash

_set_setting_value::portmaster() {
  local file="$1" name="$2" value="$3"

  local tmp
  tmp=$(jq --arg key "$name" --arg val "$value" \
    '(.[$key]) |= (if type == "number" then ($val | tonumber) elif type == "boolean" then ($val | test("true")) else $val end)' \
    "$file") && printf '%s\n' "$tmp" > "$file"
}

_get_setting_value::portmaster() {
  local file="$1" name="$2"

  jq -r --arg key "$name" '.[$key]' "$file"
}

_prepare_component::portmaster() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Performing Portmaster $action actions"
      log i "----------------------"

      rm -rf "$XDG_DATA_HOME/PortMaster"
      unzip "/app/retrodeck/components/portmaster/PortMaster.zip" -d "$XDG_DATA_HOME/"
      cp -f "$XDG_DATA_HOME/PortMaster/retrodeck/PortMaster.txt" "$XDG_DATA_HOME/PortMaster/PortMaster.sh"
      chmod +x "$XDG_DATA_HOME/PortMaster/PortMaster.sh"
      rm -f "$roms_path/portmaster/PortMaster.sh"
      install -Dm755 "$XDG_DATA_HOME/PortMaster/PortMaster.sh" "$roms_path/portmaster/PortMaster.sh"
      create_dir "$XDG_DATA_HOME/PortMaster/config/"
      cp "$component_config/config.json" "$XDG_DATA_HOME/PortMaster/config/config.json"
      set_setting_value "$rd_conf" "portmaster_path" "$rd_home_path/PortMaster" "retrodeck" "paths"
      create_dir "$portmaster_path"
    ;;

    startup)
      log i "------------------------"
      log i "Performing Portmaster $action actions"
      log i "------------------------"

      log d "Checking if PortMaster should be shown"
      if [[ $(get_setting_value "$rd_conf" "portmaster_show" "retrodeck" "options") == "false" ]]; then
        log d "Assuring that PortMaster is hidden on ES-DE"
        portmaster_show "false"
      else
        log d "Assuring that PortMaster is shown on ES-DE"
        portmaster_show "true"
      fi
    ;;

  esac
}

portmaster_show() {
  log d "Setting PortMaster visibility in ES-DE"
  if [ "$1" = "true" ]; then
    log d "\"$roms_path/portmaster/PortMaster.sh\" is not found, installing it"
    install -Dm755 "$XDG_DATA_HOME/PortMaster/PortMaster.sh" "$roms_path/portmaster/PortMaster.sh" && log d "PortMaster is correctly showing in ES-DE"
    set_setting_value "$rd_conf" "portmaster_show" "true" retrodeck "options"
  elif [ "$1" = "false" ]; then
    rm -rf "$roms_path/portmaster/PortMaster.sh" && log d "PortMaster is correctly hidden in ES-DE"
    set_setting_value "$rd_conf" "portmaster_show" "false" retrodeck "options"
  else
    log e "\"$1\" is not a valid choice, quitting"
  fi
}

configurator_portmaster_toggle_dialog() {
  if [[ $(get_setting_value "$rd_conf" "portmaster_show" "retrodeck" "options") == "true" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - PortMaster Visibility" \
    --text="PortMaster is currently <span foreground='$purple'><b>Visible</b></span> in ES-DE. Do you want to hide it?\n\n\<span foreground='$purple'><b>Note: The installed games will still be visible.</b></span>"

    if [ $? == 0 ] # User clicked "Yes"
    then
      portmaster_show "false"
      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - PortMaster Visibility" \
      --text="PortMaster is now <span foreground='$purple'><b>Hidden</b></span> in ES-DE.\n\Please refresh your game list in ES-DE or restart RetroDECK to see the changes.\n\n\To launch PortMaster, you can access it from:\n<span foreground='$purple'><b>Configurator -> Open Component -> PortMaster</b></span>."
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - PortMaster Visibility" \
    --text="PortMaster is currently <span foreground='$purple'><b>Hidden</b></span> in ES-DE. Do you want to show it?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      portmaster_show "true"
      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - PortMaster Visibility" \
      --text="PortMaster is now <span foreground='$purple'><b>Visible</b></span> in ES-DE.\nPlease refresh your game list in ES-DE or restart RetroDECK to see the changes."
    fi
  fi

  configurator_global_presets_and_settings_dialog
}

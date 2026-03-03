#!/bin/bash

portmaster_show(){
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

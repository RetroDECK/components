#!/bin/bash

component_name="$(basename "$(dirname "$0")")"
config="/app/retrodeck/config/$component_name/rd_config"

log i "-----------------------------"
log i "Prepearing Steam ROM Manager"
log i "-----------------------------"

create_dir -d "$srm_userdata"
cp -fv "$config/"*.json "$srm_userdata"
cp -fvr "$config/manifests" "$srm_userdata"

log i "Updating steamDirectory and romDirectory lines in $srm_userdata/userSettings.json"
jq '.environmentVariables.steamDirectory = "'"$HOME"'/.steam/steam"' "$srm_userdata/userSettings.json" > "$srm_userdata/tmp.json" && mv -f "$srm_userdata/tmp.json" "$srm_userdata/userSettings.json"
jq '.environmentVariables.romsDirectory = "'"$rdhome"'/.sync"' "$srm_userdata/userSettings.json" > "$srm_userdata/tmp.json" && mv -f "$srm_userdata/tmp.json" "$srm_userdata/userSettings.json"

get_steam_user
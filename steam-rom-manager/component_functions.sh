#!/bin/bash

steamsync_folder="$rd_home_path/.sync"                                                                                        # Folder containing favorites manifest for SRM
srm_userdata="$XDG_CONFIG_HOME/steam-rom-manager/userData"                                                              # SRM userdata folder, holding 
retrodeck_favorites_file="$steamsync_folder/retrodeck_favorites.json"                                                   # The current SRM manifest of all games that have been favorited in ES-DE
srm_log="$logs_path/srm_log.log"                                                                                      # Log file for capturing the output of the most recent SRM run, for debugging purposes
retrodeck_added_favorites="$steamsync_folder/retrodeck_added_favorites.json"                                            # Temporary manifest of any games that were newly added to the ES-DE favorites and should be added to Steam
retrodeck_removed_favorites="$steamsync_folder/retrodeck_removed_favorites.json"                                        # Temporary manifest of any games that were removed from the ES-DE favorites and should be removed from Steam

steam_userdata_native="$HOME/.steam/steam"
steam_userdata_flatpak="$HOME/.var/app/com.valvesoftware.Steam/.steam/steam"
steam_userdata_current=""

configurator_add_retrodeck_to_steam_dialog() {
  (
  # Add RetroDECK launcher to Steam
  rd_srm enable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
  rd_srm add >> "$srm_log" 2>&1
  ) |
  rd_zenity --progress \
  --title="RetroDECK Configurator - 🚂 Add RetroDECK to Steam 🚂" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="Adding RetroDECK to Steam...\n\n<span foreground='$purple'>Please wait until the operation is finished and you need to restart Steam afterwards.</span>" \
  --pulsate --width=500 --height=150 --auto-close --no-cancel
  configurator_steam_tools_dialog
}

configurator_automatic_steam_sync_dialog() {
  if [[ $(get_setting_value "$rd_conf" "steam_sync" retrodeck "options") == "true" ]]; then
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - 🚂 Steam Syncronization 🚂" \
    --text="Steam syncronization is <span foreground='$purple'><b>Currently: Enabled</b></span>.\nDisabling Steam Sync will remove all of your 🌟 <span foreground='$purple'><b>Favorited</b></span> 🌟 games from Steam at the next Steam startup.\n\nDo you want to continue?\n\nTo re-add them, just reenable Steam Sync then and restart Steam."

    if [ $? == 0 ] # User clicked "Yes"
    then
      configurator_disable_steam_sync
    fi
  else
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - 🚂 Steam Syncronization 🚂" \
    --text="Steam synchronization is <span foreground='$purple'><b>Currently: Disabled</b></span>. Do you want to enable it?\n\n\All 🌟 <span foreground='$purple'><b>Favorited</b></span> 🌟 games will be immediately synced to your Steam library as individual entries.\n\While this setting is enabled, RetroDECK will check your ES-DE favorites when you quit the program and update Steam using Steam ROM Manager if there are any changes.\n\n\Remember to restart Steam to see the changes.\n\n\<span foreground='$purple'><b>NOTE: Games with unusual characters in their names like &apos;/\\{}&lt;&gt;* might break the sync. Check the RetroDECK Wiki for more information.</b></span>"

    if [ $? == 0 ]
    then
      configurator_enable_steam_sync
    fi
  fi
  configurator_steam_tools_dialog
}

configurator_enable_steam_sync() {
  set_setting_value "$rd_conf" "steam_sync" "true" retrodeck "options"
  export CONFIGURATOR_GUI="zenity"
  steam_sync
  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK"  \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - 🚂 Steam Syncronization 🚂" \
      --text="Steam synchronization is <span foreground='$purple'><b>Enabled</b></span>."
}

configurator_disable_steam_sync() {
  set_setting_value "$rd_conf" "steam_sync" "false" retrodeck "options"
  # Remove only synced favorites, leave RetroDECK shortcut if it exists
  (
  rd_srm enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
  rd_srm disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
  rd_srm remove >> "$srm_log" 2>&1
  ) |
  rd_zenity --progress \
  --title="Removing RetroDECK Sync from Steam" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="Removing synced entries from Steam, please wait..." \
  --pulsate --width=500 --height=150 --auto-close --no-cancel
  if [[ -f "$retrodeck_favorites_file" ]]; then
    rm -f "$retrodeck_favorites_file"
  fi
  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK"  \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - 🚂 Steam Syncronization: Manual 🚂" \
      --text="Steam synchronization is <span foreground='$purple'><b>Disabled</b></span> and 🌟 <span foreground='$purple'><b>Favorited</b></span> 🌟 games have been removed from Steam.\nPlease restart Steam to apply the changes."
}

configurator_manual_steam_sync_dialog() {
  configurator_generic_dialog "RetroDeck Configurator - 🚂 Steam Syncronization: Manual 🚂" "RetroDECK will now look for any 🌟 <span foreground='$purple'><b>Favorited</b></span> 🌟 games and sync them to your Steam library as individual entries if needed.\n\nIf Steam Sync has been run before and no favorites have been added or removed, you will be returned to the Steam Tools menu.\nIf changes are needed, you will see a progress dialog during the process."
  export CONFIGURATOR_GUI="zenity"
  steam_sync
  configurator_steam_tools_dialog
}

configurator_purge_steam_sync_dialog() {
  if [[ $(configurator_generic_question_dialog "RetroDECK Configurator - 🚂 Steam Syncronization: Removal 🚂" "🛑 Warning 🛑\n\nAre you sure you want to remove all Steam changes, including all ES-DE 🌟 <span foreground='$purple'><b>Favorited</b></span> 🌟 games from Steam?" ) == "true" ]]; then
    (
    rd_srm nuke
    rm -f "$retrodeck_favorites_file"
    ) |
    rd_zenity --progress \
    --title="RetroDECK Configurator - 🛑 Steam Syncronization: Removing all RetroDECK data 🛑" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="<span foreground='$purple'><b>Removing all RetroDECK-related data from Steam</b></span>\n\n\The more data you have synchronized, the longer this process may take.\n\n\⏳Please wait...⏳" \
    --pulsate --width=500 --height=150 --auto-close --no-cancel
  fi
  configurator_steam_tools_dialog
}

rd_srm() {
  log d "Starting SRM"
  /bin/bash /app/retrodeck/components/steam-rom-manager/component_launcher.sh "$@"
}

get_steam_user() {
  # This function populates environment variables with the actual logged Steam user data
  local current_steam_sync_setting="$(get_setting_value "$rd_conf" "steam_sync" "retrodeck" "options")"
  if [[ "$current_steam_sync_setting" != "false" || "$1" == "finit" ]]; then # Only grab Steam information if Steam Sync is enabled
    if [[ "$current_steam_sync_setting" == "native" ]]; then
      steam_userdata_current="$steam_userdata_native"
    elif [[ "$current_steam_sync_setting" == "flatpak" ]]; then
      steam_userdata_current="$steam_userdata_flatpak"
    else
      if [[ -d "$steam_userdata_native" && -d "$steam_userdata_flatpak" ]]; then
        log w "Multiple Steam installs detected, need to choose which one to use for Steam Sync."
        choice=$(rd_zenity --title "RetroDECK - Steam Sync" --question --no-wrap --cancel-label="Flatpak" --ok-label="Native" --extra-button="None" \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --text="RetroDECK has detected data from both Native and Flatpak versions of Steam. Which type would you like Steam Sync to be enabled for?")
        if [[ $? == "0" ]]; then
          steam_userdata_current="$steam_userdata_native"
          set_setting_value "$rd_conf" "steam_sync" "native" "retrodeck" "options"
        elif [[ $? == "1" ]]; then
          steam_userdata_current="$steam_userdata_flatpak"
          set_setting_value "$rd_conf" "steam_sync" "flatpak" "retrodeck" "options"
        else
          log i "User opted to not pull any Steam Information, Steam Sync will not be enabled and controller profiles will not be installed."
          return 1
        fi
      elif [[ -d "$steam_userdata_native" ]]; then
        steam_userdata_current="$steam_userdata_native"
        set_setting_value "$rd_conf" "steam_sync" "native" "retrodeck" "options"
      elif [[ -d "$steam_userdata_flatpak" ]]; then
        steam_userdata_current="$steam_userdata_flatpak"
        set_setting_value "$rd_conf" "steam_sync" "flatpak" "retrodeck" "options"
      else
        log d "Steam Sync is enabled or this check was forced, but no Steam userdata information could be found."
        return 1
      fi
      prepare_component "reset" "steam-rom-manager"
    fi

    if [ -f "$steam_userdata_current/config/loginusers.vdf" ]; then
      # Extract the Steam ID of the most recent user
      export steam_id=$(awk '
        /"users"/ {flag=1}
        flag && /^[ \t]*"[0-9]+"/ {id=$1}
        flag && /"MostRecent".*"1"/ {print id; exit}' "$steam_userdata_current/config/loginusers.vdf" | tr -d '"')

      # Extract the Steam username (AccountName)
      export steam_username=$(awk -v steam_id="$steam_id" '
        $0 ~ steam_id {flag=1}
        flag && /"AccountName"/ {gsub(/"/, "", $2); print $2; exit}' "$steam_userdata_current/config/loginusers.vdf")

      # Extract the Steam pretty name (PersonaName)
      export steam_prettyname=$(awk -v steam_id="$steam_id" '
        $0 ~ steam_id {flag=1}
        flag && /"PersonaName"/ {gsub(/"/, "", $2); print $2; exit}' "$steam_userdata_current/config/loginusers.vdf")

      # Log success
      log i "Steam user found:"
      log i "SteamID: $steam_id"
      log i "Username: $steam_username"
      log i "Name: $steam_prettyname"

      if [[ -d "$srm_userdata" ]]; then
        populate_steamuser_srm
      fi

    else
      # Log warning if file not found
      log w "No Steam user found, proceeding" >&2
    fi
  fi
}

populate_steamuser_srm() {
  config_file="$XDG_CONFIG_HOME/steam-rom-manager/userData/userConfigurations.json"
  temp_file="${config_file}.tmp"

  if [[ ! -f "$config_file" ]]; then
    log e "Config file not found: $config_file"
    return 1
  fi

  log d "Validating $config_file..."
  if ! jq empty "$config_file" >/dev/null 2>&1; then
    log e "File is not valid JSON: $config_file"
    return 1
  fi

  log d "Applying jq transformation with username: $steam_username"
  jq --arg username "$steam_username" '
    map(
      if .userAccounts.specifiedAccounts then
        .userAccounts.specifiedAccounts = [$username]
      else
        .
      end
    )
  ' "$config_file" > "$temp_file"

  if [[ $? -eq 0 ]]; then
    mv "$temp_file" "$config_file"
    log i "Successfully updated $config_file"
  else
    log e "jq failed to write output"
    rm -f "$temp_file"
    return 1
  fi
}

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
  
  if [[ $(get_setting_value "$rd_conf" "steam_sync" retrodeck "options") =~ (flatpak) ]]; then # If Flatpak Steam, warn about permission
    configurator_generic_dialog "RetroDeck Configurator - ⚠️ Steam Flatpak Warning ⚠️" "You are using the <span foreground='purple'><b>Flatpak Version of Steam</b></span>.\n\n\To allow RetroDECK to launch, Steam must be granted the following permission:\n<span foreground='purple'><b>org.freedesktop.Flatpak</b></span>\n\n\Please read the RetroDECK wiki for instructions."
  fi
  configurator_steam_tools_dialog
}

configurator_automatic_steam_sync_dialog() {
  if [[ $(get_setting_value "$rd_conf" "steam_sync" retrodeck "options") =~ (true|native|flatpak) ]]; then
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
  if steam_type=$(get_steam_user "get_type"); then
    set_setting_value "$rd_conf" "steam_sync" "$steam_type" retrodeck "options"
    export CONFIGURATOR_GUI="zenity"
    steam_sync
    zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK"  \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Configurator - 🚂 Steam Syncronization 🚂" \
        --text="Steam synchronization is <span foreground='$purple'><b>Enabled</b></span>."
  else
    zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK"  \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Configurator - 🚂 Steam Syncronization 🚂" \
        --text="Steam synchronization could not be enabled, because your Steam install type could not be determined."
  fi
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
  local mode="${1:-}"
  local current_steam_sync_setting="$(get_setting_value "$rd_conf" "steam_sync" "retrodeck" "options")"
  if [[ "$current_steam_sync_setting" != "false" || "$mode" =~ (finit|get_type) ]]; then # Only grab Steam information if Steam Sync is enabled
    if [[ "$current_steam_sync_setting" == "native" ]]; then
      steam_userdata_current="$steam_userdata_native"
      if [[ "$mode" == "get_type" ]]; then
        echo "$current_steam_sync_setting"
        return 0
      fi
    elif [[ "$current_steam_sync_setting" == "flatpak" ]]; then
      steam_userdata_current="$steam_userdata_flatpak"
      if [[ "$mode" == "get_type" ]]; then
        echo "$current_steam_sync_setting"
        return 0
      fi
    else
      if [[ -d "$steam_userdata_native" ]]; then
        steam_userdata_current="$steam_userdata_native"
        set_setting_value "$rd_conf" "steam_sync" "native" "retrodeck" "options"
        if [[ "$mode" == "get_type" ]]; then
          echo "native"
          return 0
        fi
      elif [[ -d "$steam_userdata_flatpak" ]]; then
        steam_userdata_current="$steam_userdata_flatpak"
        set_setting_value "$rd_conf" "steam_sync" "flatpak" "retrodeck" "options"
        if [[ "$mode" == "get_type" ]]; then
          echo "flatpak"
          return 0
        fi
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

steam_sync() {

  # This function looks for favorited games in all ES-DE gamelists and builds a manifest of any found.
  # It then compares the new manifest to the existing one (if it exists) and runs an SRM sync if there are differences
  # If all favorites were removed from ES-DE, it will remove all existing entries from Steam and then remove the favorites manifest entirely
  # If there is no existing manifest, this is a first time sync and games are synced automatically
  # USAGE: steam_sync

  log "i" "Starting Steam Sync"
  create_dir "$steamsync_folder"

  if [[ ! -d "$srm_userdata" ]]; then
    log "e" "Steam ROM Manager configuration not initialized! Initializing now."
    prepare_component "reset" "steam-rom-manager"
  fi

  # Prepare fresh log file
  echo > "$srm_log"

  # Prepare new favorites manifest
  echo "[]" > "${retrodeck_favorites_file}.new" # Initialize favorites JSON file

  # Static definitions for all JSON objects
  local steam_mode=$(get_setting_value "$rd_conf" "steam_sync" "retrodeck" "options")
  if [[ "$steam_mode" =~ (true|native) ]]; then
    target="flatpak"
    launch_command="run net.retrodeck.retrodeck"
    startIn=""
  elif [[ "$steam_mode" == "flatpak" ]]; then
    target="flatpak-spawn --host"
    launch_command="flatpak run net.retrodeck.retrodeck"
    startIn=""
  else # Fallback to legacy default behavior
    target="flatpak"
    launch_command="run net.retrodeck.retrodeck"
    startIn=""
  fi

  for system_path in "$rd_home_path/ES-DE/gamelists/"*/; do
    # Skip the CLEANUP folder
    if [[ "$system_path" == *"/CLEANUP/"* ]]; then
      continue
    fi
    # Skip folders with no gamelists
    if [[ ! -f "${system_path}gamelist.xml" ]]; then
      continue
    fi
    system=$(basename "$system_path") # Extract the folder name as the system name
    log d "Checking system $system for favorites..."
    gamelist="${system_path}gamelist.xml"
    # Use AWK instead of xmlstarlet because ES-DE can create invalid XML structures in some cases
    system_favorites=$(awk 'BEGIN { RS="</game>"; FS="\n" }
                            /<favorite>true<\/favorite>/ {
                              if (match($0, /<path>([^<]+)<\/path>/, arr))
                                print arr[1]
     }' "$gamelist")
    if [[ -n "$system_favorites" ]]; then
      log d "Favorites found:"
      log d "$system_favorites"
      while read -r game_path; do
        local game="${game_path#./}" # Remove leading ./
        game=$(decode_filename "$game")
        if [[ -f "$roms_path/$system/$game" ]]; then # Validate file exists and isn't a stale ES-DE entry for a removed file
          # Construct launch options with the rom path in quotes, to handle spaces
          local game_title=$(awk -v search_path="$game_path" 'BEGIN { RS="</game>"; FS="\n" }
                                                              /<path>/ {
                                                              if (match($0, /<path>([^<]+)<\/path>/, path) && path[1] == search_path) {
                                                                if (match($0, /<name>([^<]+)<\/name>/, name))
                                                                  print name[1]
                                                                }
                                                              }' "$gamelist")
          local launchOptions="$launch_command -s $system \"$roms_path/$system/$game\""
          log d "Adding entry $launchOptions to favorites manifest."
          jq --arg title "$game_title" --arg target "$target" --arg launchOptions "$launchOptions" \
          '. += [{"title": $title, "target": $target, "launchOptions": $launchOptions}]' "${retrodeck_favorites_file}.new" > "${retrodeck_favorites_file}.tmp" \
          && mv "${retrodeck_favorites_file}.tmp" "${retrodeck_favorites_file}.new"
        elif [[ -d "$roms_path/$system/$game" && -f "$roms_path/$system/$game/$game" ]]; then # If the favorite is an .m3u multi-disc parent folder, validate the actual .m3u file also exists
          # Construct launch options with the rom path in quotes, to handle spaces
          local game_title=$(awk -v search_path="$game_path" 'BEGIN { RS="</game>"; FS="\n" }
                                                              /<path>/ {
                                                              if (match($0, /<path>([^<]+)<\/path>/, path) && path[1] == search_path) {
                                                                if (match($0, /<name>([^<]+)<\/name>/, name))
                                                                  print name[1]
                                                                }
                                                              }' "$gamelist")
          local launchOptions="$launch_command -s $system \"$roms_path/$system/$game/$game\""
          log d "Adding entry $launchOptions to favorites manifest."
          jq --arg title "$game_title" --arg target "$target" --arg launchOptions "$launchOptions" \
          '. += [{"title": $title, "target": $target, "launchOptions": $launchOptions}]' "${retrodeck_favorites_file}.new" > "${retrodeck_favorites_file}.tmp" \
          && mv "${retrodeck_favorites_file}.tmp" "${retrodeck_favorites_file}.new"
        else
          log d "Game file $roms_path/$system/$game not found, skipping..."
        fi
      done <<< "$system_favorites"
    fi
  done

  # Decide if sync needs to happen
  if [[ -f "$retrodeck_favorites_file" ]]; then # If an existing favorites manifest exists
    if [[ ! "$(cat "${retrodeck_favorites_file}.new" | jq 'length')" -gt 0 ]]; then # If all favorites were removed from all gamelists, meaning new manifest is empty
      log i "No favorites were found in current ES-DE gamelists, removing old entries"
      steam_sync_remove
      # Old manifest cleanup
      rm "$retrodeck_favorites_file"
      rm "${retrodeck_favorites_file}.new"
    else # The new favorites manifest is not empty
      if cmp -s "$retrodeck_favorites_file" "${retrodeck_favorites_file}.new"; then # See if the favorites manifests are the same, meaning there were no changes
        log i "ES-DE favorites have not changed, no need to sync again"
        rm "${retrodeck_favorites_file}.new"
      else
        # Make new favorites manifest the current one
        mv "${retrodeck_favorites_file}.new" "$retrodeck_favorites_file"
        steam_sync_add
      fi
    fi
  elif [[ "$(cat "${retrodeck_favorites_file}.new" | jq 'length')" -gt 0 ]]; then # No existing favorites manifest was found, so check if new manifest has entries
    log d "First time building favorites manifest, running sync"
    mv "${retrodeck_favorites_file}.new" "$retrodeck_favorites_file"
    steam_sync_add
  fi
}

steam_sync_add() {
  if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
    (
    rd_srm disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
    rd_srm enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
    rd_srm add >> "$srm_log" 2>&1
    ) |
    rd_zenity --progress \
    --title="RetroDECK Configurator - ⏳ Syncronizing with Steam ⏳" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="<span foreground='$purple'><b>Adding new favorited games to Steam</b></span>\n\n\<b>NOTE:</b> This may take a while depending on your library size.\n\Feel free to leave it running in the background and use another app." \
    --pulsate --width=500 --height=150 --auto-close --no-cancel
  else
    rd_srm disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
    rd_srm enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
    rd_srm add >> "$srm_log" 2>&1
  fi
}

steam_sync_remove() {
  if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
    (
    rd_srm disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
    rd_srm enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
    rd_srm remove >> "$srm_log" 2>&1
    ) |
    rd_zenity --progress \
    --title="RetroDECK Configurator - ⏳ Syncronizing with Steam ⏳" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="<span foreground='$purple'><b>Removing unfavorited games from Steam</b></span>\n\n\<b>NOTE:</b> This may take a while depending on your library size.\n\Feel free to leave it running in the background and use another app." \
    --pulsate --width=500 --height=150 --auto-close --no-cancel
  else
    rd_srm disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
    rd_srm enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
    rd_srm remove >> "$srm_log" 2>&1
  fi
}

decode_filename() {
  echo "$1" | sed \
      -e 's/&amp;/\&/g' \
      -e 's/&lt;/</g' \
      -e 's/&gt;/>/g' \
      -e 's/&quot;/"/g' \
      -e 's/&#39;/'"'"'/g'
}

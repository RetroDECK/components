#!/bin/bash

export steamsync_folder="$rd_home_path/.sync"                                                                                        # Folder containing favorites manifest for SRM
export srm_userdata="$XDG_CONFIG_HOME/steam-rom-manager/userData"                                                              # SRM userdata folder, holding 
export retrodeck_favorites_file="$steamsync_folder/retrodeck_favorites.json"                                                   # The current SRM manifest of all games that have been favorited in ES-DE
export srm_log="$logs_path/srm_log.log"                                                                                      # Log file for capturing the output of the most recent SRM run, for debugging purposes
export retrodeck_added_favorites="$steamsync_folder/retrodeck_added_favorites.json"                                            # Temporary manifest of any games that were newly added to the ES-DE favorites and should be added to Steam
export retrodeck_removed_favorites="$steamsync_folder/retrodeck_removed_favorites.json"                                        # Temporary manifest of any games that were removed from the ES-DE favorites and should be removed from Steam
export steam_controller_profiles_path="$rd_components/steam-rom-manager/controller_configs"
export steam_controller_profiles_binding_icons_path="$rd_components/steam-rom-manager/res/binding_icons"

export steam_userdata_native="$HOME/.steam/steam"
export steam_userdata_flatpak="$HOME/.var/app/com.valvesoftware.Steam/.steam/steam"
export steam_userdata_current=""

_prepare_component::steam-rom-manager() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "--------------------------------"
      log i "Resetting Steam ROM Manager"
      log i "--------------------------------"

      create_dir -d "$srm_userdata"
      cp -fv "$component_config/"*.json "$srm_userdata"
      cp -fvr "$component_config/manifests" "$srm_userdata"

      get_steam_user

      if [[ -n "$steam_userdata_current" ]]; then
        log i "Updating steamDirectory and romDirectory lines in $srm_userdata/userSettings.json"
        jq '.environmentVariables.steamDirectory = "'"$steam_userdata_current"'"' "$srm_userdata/userSettings.json" > "$srm_userdata/tmp.json" && mv -f "$srm_userdata/tmp.json" "$srm_userdata/userSettings.json"
        jq '.environmentVariables.romsDirectory = "'"$rd_home_path"'/.sync"' "$srm_userdata/userSettings.json" > "$srm_userdata/tmp.json" && mv -f "$srm_userdata/tmp.json" "$srm_userdata/userSettings.json"
      fi

      if [[ ! -z $(find "$HOME/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf") || ! -z $(find "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf") ]]; then # If RetroDECK controller profile has been previously installed
        install_retrodeck_controller_profile
      fi
    ;;

    startup)
      log i "--------------------------------"
      log i "Starting Steam ROM Manager"
      log i "--------------------------------"
      local component_path="$(get_own_component_path)"

      get_steam_user
    ;;

    shutdown)
      log i "--------------------------------"
      log i "Shutting down Steam ROM Manager"
      log i "--------------------------------"

      if [[ $(get_component_option "steam-rom-manager" "steam_sync") =~ (true|native|flatpak) ]]; then
        steam_sync "zenity"
      fi
    ;;

  esac
}

_post_update::steam-rom-manager() {
  local previous_version="$1"

  #######################################
  # These actions happen at every update
  #######################################

  if [[ ! -z $(find "$HOME/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf") || ! -z $(find "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf") ]]; then # If RetroDECK controller profile has been previously installed
    install_retrodeck_controller_profile
  fi
}

_post_update_legacy::steam-rom-manager() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.9.0b"; then
    # New components preparation
    log i "New components were added in this version, initializing them"
    prepare_component "reset" "steam-rom-manager"
  fi

  #######################################
  # These actions happen at every update
  #######################################

  if [[ ! -z $(find "$HOME/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf") || ! -z $(find "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf") ]]; then # If RetroDECK controller profile has been previously installed
    install_retrodeck_controller_profile
  fi
}

configurator_steam_tools_dialog() {
  build_zenity_menu_array choices steam_tools # Build Zenity bash array for given menu type

  choice=$(rd_zenity --list --title="RetroDECK Configurator - Steam Tools" --cancel-label="Back" --ok-label="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" --column="command" --hide-column=3 --print-column=3 \
  "${choices[@]}")

  local rc="$?"

  if [[ "$rc" -eq 0 && -n "$choice" ]]; then # User made a selection
    log d "choice: $choice"

    launch_command "$choice"
    configurator_steam_tools_dialog
  fi
}

configurator_add_retrodeck_to_steam_dialog() {
  (
  # Add RetroDECK launcher to Steam
  start::steam-rom-manager enable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
  start::steam-rom-manager add >> "$srm_log" 2>&1
  ) |
  rd_zenity --progress \
  --title="RetroDECK Configurator - Add RetroDECK to Steam" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="Adding RetroDECK to Steam...\n\n<span foreground='$purple'>Please wait until the operation is finished and you need to restart Steam afterwards.</span>" \
  --pulsate --width=500 --height=150 --auto-close --no-cancel
  
  if [[ $(get_component_option "steam-rom-manager" "steam_sync") =~ (flatpak) ]]; then # If Flatpak Steam, warn about permission
    configurator_generic_dialog "RetroDeck Configurator - Steam Flatpak Warning" "You are using the <span foreground='purple'><b>Flatpak Version of Steam</b></span>.\n\n\To allow RetroDECK to launch, Steam must be granted the following permission:\n<span foreground='purple'><b>org.freedesktop.Flatpak</b></span>\n\n\Please read the RetroDECK wiki for instructions."
  fi
}

configurator_install_retrodeck_controller_profile_dialog() {
  install_retrodeck_controller_profile

  rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Install RetroDECK Controller Profiles" \
      --text="The RetroDECK Steam Controller Profiles are now <span foreground='$purple'><b>installed</b></span>."
}

configurator_automatic_steam_sync_dialog() {
  if [[ $(get_component_option "steam-rom-manager" "steam_sync") =~ (true|native|flatpak) ]]; then
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Steam Syncronization" \
    --text="Steam syncronization is <span foreground='$purple'><b>Currently: Enabled</b></span>.\nDisabling Steam Sync will remove all of your <span foreground='$purple'><b>Favorited</b></span> games from Steam at the next Steam startup.\n\nDo you want to continue?\n\nTo re-add them, just reenable Steam Sync then and restart Steam."

    if [ $? == 0 ] # User clicked "Yes"
    then
      configurator_disable_steam_sync
    fi
  else
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Steam Syncronization" \
    --text="Steam synchronization is <span foreground='$purple'><b>Currently: Disabled</b></span>. Do you want to enable it?\n\n\All <span foreground='$purple'><b>Favorited</b></span> games will be immediately synced to your Steam library as individual entries.\n\While this setting is enabled, RetroDECK will check your ES-DE favorites when you quit the program and update Steam using Steam ROM Manager if there are any changes.\n\n\Remember to restart Steam to see the changes.\n\n\<span foreground='$purple'><b>NOTE: Games with unusual characters in their names like &apos;/\\{}&lt;&gt;* might break the sync. Check the RetroDECK Wiki for more information.</b></span>"

    if [ $? == 0 ]
    then
      configurator_enable_steam_sync
    fi
  fi
}

configurator_enable_steam_sync() {
  if steam_type=$(get_steam_user "get_type"); then
    set_component_option "steam-rom-manager" "steam_sync" "$steam_type"
    steam_sync "zenity"
    zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK"  \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Configurator - Steam Syncronization" \
        --text="Steam synchronization is <span foreground='$purple'><b>Enabled</b></span>."
  else
    zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK"  \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Configurator - Steam Syncronization" \
        --text="Steam synchronization could not be enabled, because your Steam install type could not be determined."
  fi
}

configurator_disable_steam_sync() {
  set_component_option "steam-rom-manager" "steam_sync" "false"
  # Remove only synced favorites, leave RetroDECK shortcut if it exists
  (
  start::steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
  start::steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
  start::steam-rom-manager remove >> "$srm_log" 2>&1
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
      --title "RetroDECK Configurator - Steam Syncronization: Manual" \
      --text="Steam synchronization is <span foreground='$purple'><b>Disabled</b></span> and <span foreground='$purple'><b>Favorited</b></span> games have been removed from Steam.\nPlease restart Steam to apply the changes."
}

configurator_manual_steam_sync_dialog() {
  configurator_generic_dialog "RetroDeck Configurator - Steam Syncronization: Manual" "RetroDECK will now look for any <span foreground='$purple'><b>Favorited</b></span> games and sync them to your Steam library as individual entries if needed.\n\nIf Steam Sync has been run before and no favorites have been added or removed, you will be returned to the Steam Tools menu.\nIf changes are needed, you will see a progress dialog during the process."
  steam_sync "zenity"
}

configurator_purge_steam_sync_dialog() {
  if [[ $(configurator_generic_question_dialog "RetroDECK Configurator - Steam Syncronization: Removal" "Warning: Are you sure you want to remove all Steam changes, including all ES-DE <span foreground='$purple'><b>Favorited</b></span> games from Steam?" ) == "true" ]]; then
    (
    start::steam-rom-manager nuke
    rm -f "$retrodeck_favorites_file"
    ) |
    rd_zenity --progress \
    --title="RetroDECK Configurator - Steam Syncronization: Removing all RetroDECK data" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="<span foreground='$purple'><b>Removing all RetroDECK-related data from Steam</b></span>\n\n\The more data you have synchronized, the longer this process may take.\n\nPlease wait..." \
    --pulsate --width=500 --height=150 --auto-close --no-cancel
  fi
}

start::steam-rom-manager() {
  log d "Starting Steam ROM Manager"
  local component_path="$(get_own_component_path)"
  /bin/bash ${component_path}/component_launcher.sh "$@"
}

get_steam_user() {
  # This function populates environment variables with the actual logged Steam user data
  local mode="${1:-}"
  local current_steam_sync_setting="$(get_component_option "steam-rom-manager" "steam_sync")"
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
        set_component_option "steam-rom-manager" "steam_sync" "native"
        if [[ "$mode" == "get_type" ]]; then
          echo "native"
          return 0
        fi
      elif [[ -d "$steam_userdata_flatpak" ]]; then
        steam_userdata_current="$steam_userdata_flatpak"
        set_component_option "steam-rom-manager" "steam_sync" "flatpak"
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
      log w "No Steam user found, proceeding"
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
  # USAGE: steam_sync ["$visibility_mode"]

  local visibility="${1:-}"

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
  local steam_mode=$(get_component_option "steam-rom-manager" "steam_sync")
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
      steam_sync_remove "$visibility"
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
        steam_sync_add "$visibility"
      fi
    fi
  elif [[ "$(cat "${retrodeck_favorites_file}.new" | jq 'length')" -gt 0 ]]; then # No existing favorites manifest was found, so check if new manifest has entries
    log d "First time building favorites manifest, running sync"
    mv "${retrodeck_favorites_file}.new" "$retrodeck_favorites_file"
    steam_sync_add "$visibility"
  fi
}

steam_sync_add() {
  local visibility="${1:-}"
  
  if [[ "$visibility" == "zenity" ]]; then
    (
    start::steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
    start::steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
    start::steam-rom-manager add >> "$srm_log" 2>&1
    ) |
    rd_zenity --progress \
    --title="RetroDECK Configurator - Syncronizing with Steam" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="<span foreground='$purple'><b>Adding new favorited games to Steam</b></span>\n\n\<b>NOTE:</b> This may take a while depending on your library size.\n\Feel free to leave it running in the background and use another app." \
    --pulsate --width=500 --height=150 --auto-close --no-cancel
  else
    start::steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
    start::steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
    start::steam-rom-manager add >> "$srm_log" 2>&1
  fi
}

steam_sync_remove() {
  local visibility="${1:-}"

  if [[ "$visibility" == "zenity" ]]; then
    (
    start::steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
    start::steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
    start::steam-rom-manager remove >> "$srm_log" 2>&1
    ) |
    rd_zenity --progress \
    --title="RetroDECK Configurator - Syncronizing with Steam" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="<span foreground='$purple'><b>Removing unfavorited games from Steam</b></span>\n\n\<b>NOTE:</b> This may take a while depending on your library size.\n\Feel free to leave it running in the background and use another app." \
    --pulsate --width=500 --height=150 --auto-close --no-cancel
  else
    start::steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
    start::steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
    start::steam-rom-manager remove >> "$srm_log" 2>&1
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

install_retrodeck_controller_profile() {
  # This function will install the needed files for the custom RetroDECK controller profile
  # NOTE: These files need to be stored in shared locations for Steam, outside of the normal RetroDECK folders and should always be an optional user choice
  # BIGGER NOTE: As part of this process, all emulators will need to have their configs hard-reset to match the controller mappings of the profile
  # USAGE: install_retrodeck_controller_profile
  if [[ -d "$HOME/.steam/steam/controller_base/templates/" || -d "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/" ]]; then
    if [[ -d "$HOME/.steam/steam/controller_base/templates/" ]]; then # If a normal binary Steam install exists
      rsync -rlD --mkpath "$steam_controller_profiles_binding_icons_path/" "$HOME/.steam/steam/tenfoot/resource/images/library/controller/binding_icons/"
      rsync -rlD --mkpath "$steam_controller_profiles_path/" "$HOME/.steam/steam/controller_base/templates/"
    fi
    if [[ -d "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/" ]]; then # If a Flatpak Steam install exists
      rsync -rlD --mkpath "$steam_controller_profiles_binding_icons_path/" "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/tenfoot/resource/images/library/controller/binding_icons/"
      rsync -rlD --mkpath "$steam_controller_profiles_path/" "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/"
    fi
  else
    configurator_generic_dialog "RetroDECK - Install: Steam Controller Templates" "The target directories for the controller profile do not exist.\n\nThis may occur if <span foreground='$purple'><b>Steam is not installed</b></span> or if the location does not have <span foreground='$purple'><b>read permissions</b></span>."
  fi
}

add_retrodeck_to_steam() {
  (
    log i "RetroDECK has been added to Steam"
    start::steam-rom-manager enable --names "RetroDECK Launcher"
    start::steam-rom-manager add
  ) |
  rd_zenity --progress --no-cancel --pulsate --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Adding RetroDECK to Steam" \
    --text="RetroDECK is being added to Steam.\n\n<span foreground='$purple'><b>Please wait while the process finishes...</b></span>"
  rd_zenity --info --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --text="RetroDECK has been added to Steam.\n\n\<span foreground='$purple'><b>Please restart Steam to see the changes.</b></span>"
}

install_retrodeck_controller_profile_and_add_to_steam() {
  install_retrodeck_controller_profile
  add_retrodeck_to_steam
  
  rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK Initial Install - Steam Synchronization" --cancel-label="No" --ok-label "Yes" \
    --text="Enable Steam synchronization?\n\nThis will scan your games for any <span foreground='$purple'><b>Favorited</b></span> games in ES-DE and add them to your Steam library as individual entries.\n\nYou will need to restart Steam for the changes to take effect."

  if [[ $? == 0 ]]; then
    configurator_enable_steam_sync
  fi
  if [[ $(get_component_option "steam-rom-manager" "steam_sync") =~ (flatpak) ]]; then # If Flatpak Steam, warn about permission
    configurator_generic_dialog "RetroDeck Configurator - Steam Flatpak Warning" "You are using the <span foreground='purple'><b>Flatpak Version of Steam</b></span>.\n\nTo allow RetroDECK to launch, Steam must be granted the following permission:\n<span foreground='purple'><b>org.freedesktop.Flatpak</b></span>\n\nPlease read the RetroDECK wiki for instructions"
  fi
}

finit_install_controller_profile_dialog() {
  get_steam_user "finit"
  if [[ -n "$steam_id" ]]; then
    rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK Initial Install - Add to Steam" --cancel-label="No" --ok-label "Yes" \
    --text="Would you like to install the RetroDECK Steam Controller Templates and add RetroDECK to Steam?\n\nNeeded for <span foreground='$purple'><b>optimal controller support</b></span> via Steam Input.\n\n<span foreground='$purple'><b>Highly Recommended!</b></span>"
  else
    return 1
  fi
}

#!/bin/bash

export srm_steamsync_folder="$rd_home_path/.sync"                                                                                        # Folder containing favorites manifest for SRM
export srm_userdata="$XDG_CONFIG_HOME/steam-rom-manager/userData"                                                              # SRM userdata folder
export srm_usersettings_file="$srm_userdata/userSettings.json"
export srm_userconfig_file="$srm_userdata/userConfigurations.json"
export srm_retrodeck_favorites_file="$srm_steamsync_folder/retrodeck_favorites.json"                                                   # The current SRM manifest of all games that have been favorited in ES-DE
export srm_log="$logs_path/srm_log.log"                                                                                      # Log file for capturing the output of the most recent SRM run, for debugging purposes
export srm_steam_controller_profiles_path="$rd_components/steam-rom-manager/controller_configs"
export srm_steam_controller_profiles_binding_icons_path="$rd_components/steam-rom-manager/res/binding_icons"

export srm_steam_userdata_native="$HOME/.steam/steam"
export srm_steam_userdata_flatpak="$HOME/.var/app/com.valvesoftware.Steam/.steam/steam"
export srm_steam_userdata_current=""

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

      if get_steam_user "get_type"; then
        local usersettings_temp=$(mktemp)

        log i "Updating steamDirectory and romDirectory lines in $srm_userdata/userSettings.json"
        jq --arg userdata_path "$srm_steam_userdata_current" --arg rd_home_path "$rd_home_path" '
          .environmentVariables.steamDirectory = $userdata_path |
          .environmentVariables.romsDirectory = ($rd_home_path + "/.sync")
        ' "$srm_userdata/userSettings.json" > "$usersettings_temp" && mv -f "$usersettings_temp" "$srm_userdata/userSettings.json"
      fi
    ;;

    postmove)
      if [[ -n "$srm_steam_userdata_current" ]]; then
        local usersettings_temp=$(mktemp)

        log i "Updating steamDirectory and romDirectory lines in $srm_usersettings_file"
        jq --arg userdata_path "$srm_steam_userdata_current" --arg rd_home_path "$rd_home_path" '
          .environmentVariables.steamDirectory = $userdata_path |
          .environmentVariables.romsDirectory = ($rd_home_path + "/.sync")
        ' "$srm_usersettings_file" > "$usersettings_temp" && mv -f "$usersettings_temp" "$srm_usersettings_file"
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

  install_retrodeck_controller_profile
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

  if [[ ! -z $(find "$HOME/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf" 2>/dev/null) || ! -z $(find "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf" 2>/dev/null) ]]; then # If RetroDECK controller profile has been previously installed
    install_retrodeck_controller_profile
  fi
}

start::steam-rom-manager() {
  log d "Starting Steam ROM Manager"
  local component_path="$(get_own_component_path)"
  /bin/bash ${component_path}/component_launcher.sh "$@"
}

_cli_steam_sync::steam-rom-manager() {
  local mode="${1:-}"

  if get_steam_user "manual"; then
    if [[ -n "$mode" ]]; then
      if [[ "$mode" == "purge" ]]; then
        start::steam-rom-manager nuke
        rm -f "$srm_retrodeck_favorites_file"
      else
        echo "Unknown argument \"$mode\", please check the CLI help for more information."
      fi
    else
      steam_sync
    fi
  else
    echo "Current Steam user could not be determined, cannot proceed."
  fi
  return 0
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
    configurator_nav="$choice"
  fi
}

configurator_add_retrodeck_to_steam_dialog() {
  local progress_pipe
  progress_pipe=$(mktemp -u)
  mkfifo "$progress_pipe"

  rd_zenity --progress \
  --title="RetroDECK Configurator - Add RetroDECK to Steam" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="Adding RetroDECK to Steam...\n\n<span foreground='$purple'>Please wait until the operation is finished and you need to restart Steam afterwards.</span>" \
  --pulsate --width=500 --height=150 --auto-close --no-cancel < "$progress_pipe" &
  local zenity_pid=$!

  local progress_fd
  exec {progress_fd}>"$progress_pipe"
  
  # Add RetroDECK launcher to Steam
  start::steam-rom-manager enable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
  start::steam-rom-manager add >> "$srm_log" 2>&1
  
  echo "100" >&$progress_fd

  exec {progress_fd}>&-
  wait "$zenity_pid" 2>/dev/null
  rm -f "$progress_pipe"

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
    get_steam_user
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

  local progress_pipe
  progress_pipe=$(mktemp -u)
  mkfifo "$progress_pipe"

  rd_zenity --progress \
  --title="Removing RetroDECK Sync from Steam" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="Removing synced entries from Steam, please wait..." \
  --pulsate --width=500 --height=150 --auto-close --no-cancel < "$progress_pipe" &
  local zenity_pid=$!

  local progress_fd
  exec {progress_fd}>"$progress_pipe"

  start::steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
  start::steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
  start::steam-rom-manager remove >> "$srm_log" 2>&1

  echo "100" >&$progress_fd

  exec {progress_fd}>&-
  wait "$zenity_pid" 2>/dev/null
  rm -f "$progress_pipe"
  
  if [[ -f "$srm_retrodeck_favorites_file" ]]; then
    rm -f "$srm_retrodeck_favorites_file"
  fi
  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK"  \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Steam Syncronization: Manual" \
      --text="Steam synchronization is <span foreground='$purple'><b>Disabled</b></span> and <span foreground='$purple'><b>Favorited</b></span> games have been removed from Steam.\nPlease restart Steam to apply the changes."
}

configurator_manual_steam_sync_dialog() {
  configurator_generic_dialog "RetroDeck Configurator - Steam Syncronization: Manual" "RetroDECK will now look for any <span foreground='$purple'><b>Favorited</b></span> games and sync them to your Steam library as individual entries if needed.\n\nIf Steam Sync has been run before and no favorites have been added or removed, you will be returned to the Steam Tools menu.\nIf changes are needed, you will see a progress dialog during the process."
  if get_steam_user "manual"; then
    steam_sync "zenity"
  else
    configurator_generic_dialog "RetroDeck Configurator - Steam Syncronization: Manual" "RetroDECK could not determine the logged-in Steam user information.\n\nManual Steam sync could not be performed."
  fi
}

configurator_purge_steam_sync_dialog() {
  if configurator_generic_question_dialog "RetroDECK Configurator - Steam Syncronization: Removal" "Warning: Are you sure you want to remove all Steam changes, including all ES-DE <span foreground='$purple'><b>Favorited</b></span> games from Steam?"; then

    local progress_pipe
    progress_pipe=$(mktemp -u)
    mkfifo "$progress_pipe"

    rd_zenity --progress \
    --title="RetroDECK Configurator - Steam Syncronization: Removing all RetroDECK data" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="<span foreground='$purple'><b>Removing all RetroDECK-related data from Steam</b></span>\n\n\The more data you have synchronized, the longer this process may take.\n\nPlease wait..." \
    --pulsate --width=500 --height=150 --auto-close --no-cancel < "$progress_pipe" &
    local zenity_pid=$!

    local progress_fd
    exec {progress_fd}>"$progress_pipe"

    start::steam-rom-manager nuke
    rm -f "$srm_retrodeck_favorites_file"

    echo "100" >&$progress_fd

    exec {progress_fd}>&-
    wait "$zenity_pid" 2>/dev/null
    rm -f "$progress_pipe"
  fi
}

get_steam_user() {
  # This function populates environment variables with the actual logged Steam user data
  local mode="${1:-}"
  local current_steam_sync_setting="$(get_component_option "steam-rom-manager" "steam_sync")"
  if [[ "$current_steam_sync_setting" != "false" || "$mode" =~ (get_type|manual) ]]; then # Only grab Steam information if Steam Sync is enabled or if otherwise overridden
    local srm_rd_manifest_target
    if [[ "$current_steam_sync_setting" == "native" ]]; then
      export srm_steam_userdata_current="$srm_steam_userdata_native"
      srm_rd_manifest_target="flatpak"
      if [[ "$mode" == "get_type" ]]; then
        echo "$current_steam_sync_setting"
        return 0
      fi
    elif [[ "$current_steam_sync_setting" == "flatpak" ]]; then
      export srm_steam_userdata_current="$srm_steam_userdata_flatpak"
      srm_rd_manifest_target="flatpak-spawn --host"
      if [[ "$mode" == "get_type" ]]; then
        echo "$current_steam_sync_setting"
        return 0
      fi
    else
      if [[ -d "$srm_steam_userdata_native" ]]; then
        if [[ "$mode" == "get_type" ]]; then
          echo "native"
          return 0
        fi
        export srm_steam_userdata_current="$srm_steam_userdata_native"
      elif [[ -d "$srm_steam_userdata_flatpak" ]]; then
        if [[ "$mode" == "get_type" ]]; then
          echo "flatpak"
          return 0
        fi
        export srm_steam_userdata_current="$srm_steam_userdata_flatpak"
      else
        log d "No Steam userdata information could be found."
        return 1
      fi
    fi

    if [[ -f "$srm_steam_userdata_current/config/loginusers.vdf" ]]; then
      # Extract the Steam ID of the most recent user
      export steam_id=$(awk '
        /"users"/ {flag=1}
        flag && /^[ \t]*"[0-9]+"/ {id=$1}
        flag && /"MostRecent".*"1"/ {print id; exit}' "$srm_steam_userdata_current/config/loginusers.vdf" | tr -d '"')

      # Extract the Steam username (AccountName)
      export steam_username=$(awk -v steam_id="$steam_id" '
        $0 ~ steam_id {flag=1}
        flag && /"AccountName"/ {gsub(/"/, "", $2); print $2; exit}' "$srm_steam_userdata_current/config/loginusers.vdf")

      # Extract the Steam pretty name (PersonaName)
      export steam_prettyname=$(awk -v steam_id="$steam_id" '
        $0 ~ steam_id {flag=1}
        flag && /"PersonaName"/ {gsub(/"/, "", $2); print $2; exit}' "$srm_steam_userdata_current/config/loginusers.vdf")

      # Log success
      log i "Steam user found:"
      log i "SteamID: $steam_id"
      log i "Username: $steam_username"
      log i "Name: $steam_prettyname"

      log i "Updating steamDirectory and romDirectory lines in $srm_userdata/userSettings.json"
      local usersettings_temp=$(mktemp)
      jq --arg userdata_path "$srm_steam_userdata_current" --arg rd_home_path "$rd_home_path" '
        .environmentVariables.steamDirectory = $userdata_path |
        .environmentVariables.romsDirectory = ($rd_home_path + "/.sync")
      ' "$srm_userdata/userSettings.json" > "$usersettings_temp" && mv -f "$usersettings_temp" "$srm_userdata/userSettings.json"

      log i "Updating launch target in $srm_userdata/manifests/RetroDECK.json"
      local srm_rd_manifest_temp=$(mktemp)
      jq --arg target "$srm_rd_manifest_target" '
        .target = $target
      ' "$srm_userdata/manifests/RetroDECK.json" > "$srm_rd_manifest_temp" && mv -f "$srm_rd_manifest_temp" "$srm_userdata/manifests/RetroDECK.json"

      if ! populate_steamuser_srm; then
        log e "Steam username could not be populated in SRM config files."
        return 1
      fi
    else
      log w "No Steam user found, proceeding"
      return 1
    fi
  fi
}

populate_steamuser_srm() {
  local temp_file=$(mktemp)

  if [[ ! -f "$srm_userconfig_file" ]]; then
    log e "Config file not found: $srm_userconfig_file"
    return 1
  fi

  log d "Validating $srm_userconfig_file..."
  if ! jq empty "$srm_userconfig_file" >/dev/null 2>&1; then
    log e "File is not valid JSON: $srm_userconfig_file"
    return 1
  fi

  if [[ -n $steam_username ]]; then
    log d "Updating Steam username $steam_username in $srm_userconfig_file"
    jq --arg username "$steam_username" '
      map(
        if .userAccounts.specifiedAccounts then
          .userAccounts.specifiedAccounts = [$username]
        else
          .
        end
      )
    ' "$srm_userconfig_file" > "$temp_file" && mv -f "$temp_file" "$srm_userconfig_file"
  else
    log e "Steam username not loaded, cannot populate values in $srm_userconfig_file"
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
  create_dir "$srm_steamsync_folder"

  if [[ ! -d "$srm_userdata" ]]; then
    log "e" "Steam ROM Manager configuration not initialized! Initializing now."
    prepare_component "reset" "steam-rom-manager"
  fi

  # Prepare fresh log file
  echo > "$srm_log"

  # Determine launch configuration from component settings
  local steam_mode
  steam_mode=$(get_component_option "steam-rom-manager" "steam_sync")

  local target launch_command
  case "$steam_mode" in
    true|native)
      target="flatpak"
      launch_command="run net.retrodeck.retrodeck"
      ;;
    flatpak)
      target="flatpak-spawn --host"
      launch_command="flatpak run net.retrodeck.retrodeck"
      ;;
    *)  # Fallback to legacy default behavior
      target="flatpak"
      launch_command="run net.retrodeck.retrodeck"
      ;;
  esac

  # Collect all favorite entries across all systems
  local -a manifest_entries=()

  for system_path in "$esde_gamelists_path/"*/; do
    # Skip the CLEANUP folder and folders with no gamelist
    [[ "$system_path" == *"/CLEANUP/"* ]] && continue
    local gamelist="${system_path}gamelist.xml"
    [[ ! -f "$gamelist" ]] && continue

    local system
    system=$(basename "$system_path")
    log d "Checking system $system for favorites..."

    local favorites_data
    favorites_data=$(xmlstarlet sel -t \
      -m '//game[favorite="true"]' \
      -v 'path' -o $'\t' -v 'name' -n \
      "$gamelist" 2>/dev/null) || true

    [[ -z "$favorites_data" ]] && continue

    log d "Favorites found in $system"

    while IFS=$'\t' read -r game_path game_title; do
      [[ -z "$game_path" ]] && continue
      local game="${game_path#./}"  # Remove leading ./

      # Resolve the actual launch path, handling both regular files and m3u multi-disc directories
      local launch_path=""
      if [[ -f "$roms_path/$system/$game" ]]; then
        launch_path="$roms_path/$system/$game"
      elif [[ -d "$roms_path/$system/$game" && -f "$roms_path/$system/$game/$game" ]]; then
        launch_path="$roms_path/$system/$game/$game"
      else
        log d "Game file $roms_path/$system/$game not found, skipping..."
        continue
      fi

      local launch_options="$launch_command -s $system \"$launch_path\""
      log d "Adding entry $launch_options to favorites manifest."

      # Collect as JSON
      manifest_entries+=("$(jq -nc \
        --arg title "$game_title" \
        --arg target "$target" \
        --arg launch_options "$launch_options" \
        '{"title": $title, "target": $target, "launchOptions": $launch_options}')")
    done <<< "$favorites_data"
  done

  # Build the new manifest
  local new_manifest="${srm_retrodeck_favorites_file}.new"
  if [[ ${#manifest_entries[@]} -gt 0 ]]; then
    printf '%s\n' "${manifest_entries[@]}" | jq -s '.' > "$new_manifest"
  else
    echo '[]' > "$new_manifest"
  fi

  # Decide if sync needs to happen
  if [[ -f "$srm_retrodeck_favorites_file" ]]; then
    if [[ ${#manifest_entries[@]} -eq 0 ]]; then
      log i "No favorites were found in current ES-DE gamelists, removing old entries"
      steam_sync_remove "$visibility"
      rm "$srm_retrodeck_favorites_file"
      rm "$new_manifest"
    elif cmp -s "$srm_retrodeck_favorites_file" "$new_manifest"; then
      log i "ES-DE favorites have not changed, no need to sync again"
      rm "$new_manifest"
    else
      mv "$new_manifest" "$srm_retrodeck_favorites_file"
      steam_sync_add "$visibility"
    fi
  elif [[ ${#manifest_entries[@]} -gt 0 ]]; then
    log d "First time building favorites manifest, running sync"
    mv "$new_manifest" "$srm_retrodeck_favorites_file"
    steam_sync_add "$visibility"
  else
    rm "$new_manifest"
  fi
}

steam_sync_add() {
  local visibility="${1:-}"
  
  if [[ "$visibility" == "zenity" ]]; then
    local progress_pipe
    progress_pipe=$(mktemp -u)
    mkfifo "$progress_pipe"

    rd_zenity --progress \
    --title="RetroDECK Configurator - Syncronizing with Steam" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="<span foreground='$purple'><b>Adding new favorited games to Steam</b></span>\n\n\<b>NOTE:</b> This may take a while depending on your library size.\n\Feel free to leave it running in the background and use another app." \
    --pulsate --width=500 --height=150 --auto-close --no-cancel < "$progress_pipe" &
    local zenity_pid=$!

    local progress_fd
    exec {progress_fd}>"$progress_pipe"
  fi

    start::steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
    start::steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
    start::steam-rom-manager add >> "$srm_log" 2>&1
    
  if [[ "$visibility" == "zenity" ]]; then
    echo "100" >&$progress_fd

    exec {progress_fd}>&-
    wait "$zenity_pid" 2>/dev/null
    rm -f "$progress_pipe"
  fi
}

steam_sync_remove() {
  local visibility="${1:-}"
  
  if [[ "$visibility" == "zenity" ]]; then
    local progress_pipe
    progress_pipe=$(mktemp -u)
    mkfifo "$progress_pipe"
    
    rd_zenity --progress \
    --title="RetroDECK Configurator - Syncronizing with Steam" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="<span foreground='$purple'><b>Removing unfavorited games from Steam</b></span>\n\n\<b>NOTE:</b> This may take a while depending on your library size.\n\Feel free to leave it running in the background and use another app." \
    --pulsate --width=500 --height=150 --auto-close --no-cancel < "$progress_pipe" &
    local zenity_pid=$!

    local progress_fd
    exec {progress_fd}>"$progress_pipe"
  fi

  start::steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
  start::steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
  start::steam-rom-manager remove >> "$srm_log" 2>&1

  if [[ "$visibility" == "zenity" ]]; then
    echo "100" >&$progress_fd

    exec {progress_fd}>&-
    wait "$zenity_pid" 2>/dev/null
    rm -f "$progress_pipe"
  fi
}

install_retrodeck_controller_profile() {
  # This function will install the needed files for the custom RetroDECK controller profile
  # USAGE: install_retrodeck_controller_profile
  local mode="{$1:-}"
  local current_steam_sync_setting="$(get_component_option "steam-rom-manager" "steam_sync")"

  if [[ ("$current_steam_sync_setting" == "native" || "$mode" == "manual") && -d "$srm_steam_userdata_native/controller_base/templates/" ]]; then
    rsync -rlD --mkpath "$srm_steam_controller_profiles_binding_icons_path/" "$srm_steam_userdata_native/tenfoot/resource/images/library/controller/binding_icons/"
    rsync -rlD --mkpath "$srm_steam_controller_profiles_path/" "$srm_steam_userdata_native/controller_base/templates/"
  elif [[ ("$current_steam_sync_setting" == "flatpak" || "$mode" == "manual") && -d "$srm_steam_userdata_flatpak/controller_base/templates/" ]]; then
    rsync -rlD --mkpath "$srm_steam_controller_profiles_binding_icons_path/" "$srm_steam_userdata_flatpak/tenfoot/resource/images/library/controller/binding_icons/"
    rsync -rlD --mkpath "$srm_steam_controller_profiles_path/" "$srm_steam_userdata_flatpak/controller_base/templates/"
  else
    configurator_generic_dialog "RetroDECK - Install: Steam Controller Templates" "The target directories for the controller profile do not exist.\n\nThis may occur if <span foreground='$purple'><b>Steam is not installed</b></span> or if the location does not have <span foreground='$purple'><b>read permissions</b></span>."
  fi
}

add_retrodeck_to_steam() {
  local progress_pipe
  progress_pipe=$(mktemp -u)
  mkfifo "$progress_pipe"

  rd_zenity --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - Adding RetroDECK to Steam" \
  --text="RetroDECK is being added to Steam.\n\n<span foreground='$purple'><b>Please wait while the process finishes...</b></span>" < "$progress_pipe" &
  local zenity_pid=$!
  
  local progress_fd
  exec {progress_fd}>"$progress_pipe"
  
  log i "RetroDECK is being added to Steam"
  start::steam-rom-manager enable --names "RetroDECK Launcher"
  start::steam-rom-manager add

  echo "100" >&$progress_fd

  exec {progress_fd}>&-
  wait "$zenity_pid" 2>/dev/null
  rm -f "$progress_pipe"
  
  rd_zenity --info --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --text="RetroDECK has been added to Steam.\n\n\<span foreground='$purple'><b>Please restart Steam to see the changes.</b></span>"
}

install_retrodeck_controller_profile_and_add_to_steam() {
  install_retrodeck_controller_profile "manual"
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
  if get_steam_user "get_type"; then
    rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK Initial Install - Add to Steam" --cancel-label="No" --ok-label "Yes" \
    --text="Would you like to install the RetroDECK Steam Controller Templates and add RetroDECK to Steam?\n\nNeeded for <span foreground='$purple'><b>optimal controller support</b></span> via Steam Input.\n\n<span foreground='$purple'><b>Highly Recommended!</b></span>"
  else
    return 1
  fi
}

finit_install_controller_profile_and_add_retrodeck_to_steam() {
  if get_steam_user "manual"; then
    log i "Updating steamDirectory and romDirectory lines in $srm_usersettings_file"
    local usersettings_temp=$(mktemp)
    jq --arg userdata_path "$srm_steam_userdata_current" --arg rd_home_path "$rd_home_path" '
      .environmentVariables.steamDirectory = $userdata_path |
      .environmentVariables.romsDirectory = ($rd_home_path + "/.sync")
    ' "$srm_usersettings_file" > "$usersettings_temp" && mv -f "$usersettings_temp" "$srm_usersettings_file"
    
    install_retrodeck_controller_profile_and_add_to_steam
  else
    configurator_generic_dialog "RetroDECK - Install Controller Profiles and Add RetroDECK to Steam" "Your Steam username could not be determined.\n\nAlthough our initial checks have passed, something else is wrong.\nThere may be an issue with your Steam install."
  fi
}

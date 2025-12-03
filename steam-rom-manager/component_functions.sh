#!/bin/bash

steamsync_folder="$rd_home_path/.sync"                                                                                        # Folder containing favorites manifest for SRM
srm_userdata="$XDG_CONFIG_HOME/steam-rom-manager/userData"                                                              # SRM userdata folder, holding 
retrodeck_favorites_file="$steamsync_folder/retrodeck_favorites.json"                                                   # The current SRM manifest of all games that have been favorited in ES-DE
srm_log="$logs_path/srm_log.log"                                                                                      # Log file for capturing the output of the most recent SRM run, for debugging purposes
retrodeck_added_favorites="$steamsync_folder/retrodeck_added_favorites.json"                                            # Temporary manifest of any games that were newly added to the ES-DE favorites and should be added to Steam
retrodeck_removed_favorites="$steamsync_folder/retrodeck_removed_favorites.json"                                        # Temporary manifest of any games that were removed from the ES-DE favorites and should be removed from Steam

configurator_add_retrodeck_to_steam_dialog() {
  (
  # Add RetroDECK launcher to Steam
  rd_srm enable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
  rd_srm add >> "$srm_log" 2>&1
  ) |
  rd_zenity --progress \
  --title="RetroDECK Configurator: Add RetroDECK to Steam" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="Adding RetroDECK to Steam...\n\n<span foreground='$purple'>Please wait until the operation is finished and you need to restart Steam afterwards.</span>" \
  --pulsate --width=500 --height=150 --auto-close --no-cancel
  configurator_steam_tools_dialog
}

configurator_automatic_steam_sync_dialog() {
  if [[ $(get_setting_value "$rd_conf" "steam_sync" retrodeck "options") == "true" ]]; then
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Steam Syncronization" \
    --text="Steam syncronization is <span foreground='$purple'><b>Currently: Enabled</b></span>.\nDisabling Steam Sync will remove all of your favorites from Steam at the next Steam startup.\n\nDo you want to continue?\n\nTo re-add them, just reenable Steam Sync then and restart Steam."

    if [ $? == 0 ] # User clicked "Yes"
    then
      configurator_disable_steam_sync
    fi
  else
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Steam Syncronization" \
    --text="Steam synchronization is <span foreground='$purple'><b>Currently: Disabled</b></span>. Do you want to enable it?\n\n\All favorited games will be immediately synced with Steam ROM Manager.\n\While this setting is enabled, RetroDECK will check your ES-DE favorites when you quit the program and update Steam using Steam ROM Manager if there are any changes.\n\n\Remember to restart Steam to see the changes.\n\n\<span foreground='$purple'><b>NOTE: Games with unusual characters in their names like &apos;/\\{}&lt;&gt;* might break the sync. Check the RetroDECK Wiki for more information.</b></span>"

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
  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK 🟢"  \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - RetroDECK Steam Syncronization" \
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
  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK 🟢"  \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - RetroDECK Steam Syncronization" \
      --text="Steam synchronization is <span foreground='$purple'><b>Disabled</b></span> and shortcuts have been removed.\nPlease restart Steam to apply the changes."
}

configurator_manual_steam_sync_dialog() {
  configurator_generic_dialog "RetroDeck Configurator - Manual Steam Sync" "RetroDECK will now look for any ES-DE favorites and sync them to Steam, if needed.\n\nIf Steam Sync has been run before and no favorites have been added or removed, you will be returned to the Steam Tools menu.\nIf changes are needed, you will see a progress dialog during the process."
  export CONFIGURATOR_GUI="zenity"
  steam_sync
  configurator_steam_tools_dialog
}

configurator_purge_steam_sync_dialog() {
  if [[ $(configurator_generic_question_dialog "RetroDECK Configurator - Steam Sync" "Are you sure you want to remove all Steam ROM Manager changes, including all RetroDECK shortcuts from Steam?" ) == "true" ]]; then
    (
    rd_srm nuke
    rm -f "$retrodeck_favorites_file"
    ) |
    rd_zenity --progress \
    --title="Removing all RetroDECK Steam Sync information" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="<span foreground='$purple'><b>\t\t\t\tRemoving all RetroDECK-related data from Steam</b></span>\n\nPlease wait..." \
    --pulsate --width=500 --height=150 --auto-close --no-cancel
  fi
  configurator_steam_tools_dialog
}

rd_srm() {
  log d "Starting SRM"
  /bin/bash /app/retrodeck/components/steam-rom-manager/component_launcher.sh "$@"
}

#!/bin/bash

export es_de_appdata_path="$XDG_CONFIG_HOME/ES-DE"
export es_de_config="$XDG_CONFIG_HOME/ES-DE/settings/es_settings.xml"
export es_de_logs_path="$XDG_CONFIG_HOME/ES-DE/logs"
export es_systems="/app/retrodeck/components/es-de/share/es-de/resources/systems/linux/es_systems.xml"                                     # ES-DE supported system list
export es_find_rules="/app/retrodeck/components/es-de/share/es-de/resources/systems/linux/es_find_rules.xml"                               # ES-DE emulator find rules
export splashscreen_dir="/app/retrodeck/graphics/extra_splashes"                                   # The default location of extra splash screens
export current_splash_file="$XDG_CONFIG_HOME/ES-DE/resources/graphics/splash.svg"                                    # The active splash file that will be shown on boot
export default_splash_file="/app/retrodeck/graphics/splash.svg"                               # The default RetroDECK splash screen

_set_setting_value::es-de() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")

  sed -i 's^'"$name"'" value=".*"^'"$name"'" value="'"$value"'"^' "$file"
}

_get_setting_value::es-de() {
  local file="$1" name="$2"
  sed -n 's^.*name="'"$(sed_escape_pattern "$name")"'" value="\(.*\)".*^\1^p' "$file"
}

_prepare_component::es-de() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "--------------------------------"
      log i "Resetting ES-DE"
      log i "--------------------------------"

      rm -rf "$XDG_CONFIG_HOME/ES-DE"
      create_dir "$XDG_CONFIG_HOME/ES-DE/settings"
      log d "Preparing es_settings.xml"
      cp -f "$component_config/es_settings.xml" "$es_de_config"
      set_setting_value "$es_de_config" "Theme" "RetroDECK-theme-main" "es-de"
      set_setting_value "$es_de_config" "ROMDirectory" "$roms_path" "es-de"
      set_setting_value "$es_de_config" "MediaDirectory" "$downloaded_media_path" "es-de"
      set_setting_value "$es_de_config" "UserThemeDirectory" "$themes_path" "es-de"
      dir_prep "$rd_home_path/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists"
      dir_prep "$rd_home_path/ES-DE/collections" "$XDG_CONFIG_HOME/ES-DE/collections"
      dir_prep "$rd_home_path/ES-DE/scripts" "$XDG_CONFIG_HOME/ES-DE/scripts"
      dir_prep "$rd_home_path/ES-DE/screensavers" "$XDG_CONFIG_HOME/ES-DE/screensavers"
      dir_prep "$rd_home_path/ES-DE/custom_systems" "$XDG_CONFIG_HOME/ES-DE/custom_systems"
      dir_prep "$logs_path/ES-DE" "$XDG_CONFIG_HOME/ES-DE/logs"
      log d "Generating roms system folders"
      start::es-de --create-system-dirs
    ;;

    postmove)
      log i "--------------------------------"
      log i "Post-moving ES-DE"
      log i "--------------------------------"

      set_setting_value "$es_de_config" "ROMDirectory" "$roms_path" "es-de"
      set_setting_value "$es_de_config" "MediaDirectory" "$downloaded_media_path" "es-de"
      set_setting_value "$es_de_config" "UserThemeDirectory" "$themes_path" "es-de"
      dir_prep "$rd_home_path/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists"
      dir_prep "$rd_home_path/ES-DE/collections" "$XDG_CONFIG_HOME/ES-DE/collections"
      dir_prep "$rd_home_path/ES-DE/scripts" "$XDG_CONFIG_HOME/ES-DE/scripts"
      dir_prep "$rd_home_path/ES-DE/screensavers" "$XDG_CONFIG_HOME/ES-DE/screensavers"
      dir_prep "$rd_home_path/ES-DE/custom_systems" "$XDG_CONFIG_HOME/ES-DE/custom_systems"
      dir_prep "$logs_path/ES-DE" "$XDG_CONFIG_HOME/ES-DE/logs"
    ;;

    startup)
      log i "--------------------------------"
      log i "Starting ES-DE"
      log i "--------------------------------"
      local component_path="$(get_own_component_path)"

      splash_screen::es-de
  
      log i "Starting ES-DE"
      start::es-de "$@"
    ;;

    shutdown)
      log i "--------------------------------"
      log i "Shutting down ES-DE"
      log i "--------------------------------"

      log i "Quitting ES-DE"
      pkill -f "es-de"
    ;;

  esac
}

start::es-de(){
  log d "Starting ES-DE"

  local component_path="$(get_own_component_path)"
  /bin/bash ${component_path}/component_launcher.sh "$@"
}

splash_screen::es-de() {
  # This function will replace the RetroDECK startup splash screen with a different image if the day and time match a listing in the JSON data.
  # USAGE: splash_screen

  current_day=$(date +"%m%d")  # Read the current date in a format that can be calculated in ranges
  current_time=$(date +"%H%M") # Read the current time in a format that can be calculated in ranges

  # Read the JSON file and extract splash screen data using jq
  splash_screen=$(get_component_manifest_cache | jq -r --arg current_day "$current_day" --arg current_time "$current_time" '
    .[] | .manifest | select(has("es-de")) | .["es-de"].splash_screens |
    to_entries[] |
    select(
      ($current_day | tonumber) >= (.value.start_date | tonumber) and
      ($current_day | tonumber) <= (.value.end_date | tonumber) and
      ($current_time | tonumber) >= (.value.start_time | tonumber) and
      ($current_time | tonumber) <= (.value.end_time | tonumber)
    ) | .value.filename
  ')

  # Determine the splash file to use
  if [[ -n "$splash_screen" ]]; then
    new_splash_file="$splashscreen_dir/$splash_screen"
  else
    new_splash_file="$default_splash_file"
  fi

  mkdir -p "$XDG_CONFIG_HOME/ES-DE/resources/graphics"
  cp -f "$new_splash_file" "$current_splash_file"
}

configurator_rebuild_esde_systems::es-de() {
  start::es-de --create-system-dirs
  local current_iconset=$(get_setting_value "$rd_conf" "iconset" "retrodeck" "options")
  if [[ ! "$current_iconset" == "false" ]]; then
    (
    handle_folder_iconsets "$current_iconset"
    ) |
    rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator Utility - Rebuilding Folder Iconsets In Progress"
  fi
  configurator_generic_dialog "RetroDECK Configurator - Rebuild System Folders" "<span foreground='$purple'><b>The rebuilding process is complete.</b></span>\n\nAll missing default system folders will now exist in <span foreground='$purple'><b>$roms_path</b></span>."
  configurator_data_management_dialog
}

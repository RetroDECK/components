#!/bin/bash

export es_de_appdata_path="$XDG_CONFIG_HOME/ES-DE"
export es_de_config="$XDG_CONFIG_HOME/ES-DE/settings/es_settings.xml"
export es_de_logs_path="$XDG_CONFIG_HOME/ES-DE/logs"
export es_systems="$rd_components/es-de/share/es-de/resources/systems/linux/es_systems.xml"                                     # ES-DE supported system list
export es_find_rules="$rd_components/es-de/share/es-de/resources/systems/linux/es_find_rules.xml"                               # ES-DE emulator find rules
export splashscreen_dir="$rd_components/es-de/res/extra_splashes"                                   # The default location of extra splash screens
export current_splash_file="$XDG_CONFIG_HOME/ES-DE/resources/graphics/splash.svg"                                    # The active splash file that will be shown on boot
export default_splash_file="$rd_components/es-de/res/splash.svg"                               # The default RetroDECK splash screen

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
}

_post_update::es-de() {
  local previous_version="$1"

}

_post_update_legacy::es-de() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.7.0b"; then
    # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
    # - Expose ES-DE gamelists folder to user at ~/retrodeck/gamelists
    # - Disable ESDE update checks for existing installs
    # - Set ESDE user themes folder directly

    dir_prep "$rdhome/gamelists" "$XDG_CONFIG_HOME/emulationstation/ES-DE/gamelists"

    set_setting_value "$es_settings" "ApplicationUpdaterFrequency" "never" "es-de"

    rm -rf "$XDG_CONFIG_HOME/emulationstation/ES-DE/gamelists/tools/"

    set_setting_value "$es_settings" "ROMDirectory" "$roms_path" "es-de"
    set_setting_value "$es_settings" "MediaDirectory" "$media_path" "es-de"
    sed -i '$ a <string name="UserThemeDirectory" value="" />' "$es_settings" # Add new default line to existing file
    set_setting_value "$es_settings" "UserThemeDirectory" "$themes_path" "es-de"
    unlink "$XDG_CONFIG_HOME/emulationstation/ROMs"
    unlink "$XDG_CONFIG_HOME/emulationstation/ES-DE/downloaded_media"
    unlink "$XDG_CONFIG_HOME/emulationstation/ES-DE/themes"
  fi

  if check_version_is_older_than "$previous_version" "0.7.3b"; then
    # In version 0.7.3b, there was a bug that prevented the correct creations of the roms/system folders, so we force recreate them.
    start::es-de --home "$XDG_CONFIG_HOME/emulationstation" --create-system-dirs
  fi

  if check_version_is_older_than "$previous_version" "0.8.0b"; then
    log i "In version 0.8.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:"
    log i "- The following components are been added and need to be initialized: es-de 3.0, MAME-SA, Vita3K, GZDoom"

    # in 3.0 .emulationstation was moved into ES-DE
    log i "Renaming old \"$XDG_CONFIG_HOME/emulationstation\" folder as \"$XDG_CONFIG_HOME/ES-DE\""
    mv -f "$XDG_CONFIG_HOME/emulationstation" "$XDG_CONFIG_HOME/ES-DE"

    prepare_component "reset" "es-de"

    log i "New systems were added in this version, regenerating system folders."
    #es-de --home "$XDG_CONFIG_HOME/" --create-system-dirs
    start::es-de --create-system-dirs
  fi

  if check_version_is_older_than "$previous_version" "0.8.1b"; then
    log i "In version 0.8.1b, the following changes were made that required config file updates/reset or other changes to the filesystem:"
    log i "- ES-DE files were moved inside the retrodeck folder, migrating to the new structure"

    log d "ES-DE files were moved inside the retrodeck folder, migrating to the new structure"
    dir_prep "$rdhome/ES-DE/collections" "$XDG_CONFIG_HOME/ES-DE/collections"
    dir_prep "$rdhome/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists"
    log i "Moving ES-DE collections, downloaded_media, gamelist, and themes from \"$rdhome\" to \"$rdhome/ES-DE\""
    set_setting_value "$es_settings" "MediaDirectory" "$rdhome/ES-DE/downloaded_media" "es-de"
    set_setting_value "$es_settings" "UserThemeDirectory" "$rdhome/ES-DE/themes" "es-de"
    mv -f "$rdhome/themes" "$rdhome/ES-DE/themes" && log d "Move of \"$rdhome/themes\" in \"$rdhome/ES-DE\" folder completed"
    mv -f "$rdhome/downloaded_media" "$rdhome/ES-DE/downloaded_media" && log d "Move of \"$rdhome/downloaded_media\" in \"$rdhome/ES-DE\" folder completed"
    mv -f "$rdhome/gamelists/"* "$rdhome/ES-DE/gamelists" && log d "Move of \"$rdhome/gamelists/\" in \"$rdhome/ES-DE\" folder completed" && rm -rf "$rdhome/gamelists"
  fi

  if check_version_is_older_than "$previous_version" "0.9.4b"; then
    # Between updates of ES-DE to 3.2, it looks like some required graphics files may not be created on an existing install
    # We will use rsync to ensure that the shipped graphics and the location ES-DE is looking in are correct
    rsync -rlD --mkpath "/app/retrodeck/graphics/" "/var/config/ES-DE/resources/graphics/"
    dir_prep "$rdhome/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists" # Fix broken symlink in case user had moved an ES-DE folder after they were consolidated into ~/retrodeck/ES-DE
  fi

  if check_version_is_older_than "$previous_version" "0.10.0b"; then
    # With the RetroDECK Neo the theme folder is changed, so if the user set the RetroDECK Theme we need to fix the name in the config

    if [[ $(get_setting_value "$es_de_config" "Theme" "es-de") == "retrodeck" ]]; then
      log i "0.10.0b Upgrade - Postmove: ES-DE - Default RetroDECK theme is set, fixing theme name in ES-DE config"
      set_setting_value "$es_de_config" "Theme" "RetroDECK-theme-main" "es-de"

      prepare_component "postmove" "es-de"
    fi
  fi
}

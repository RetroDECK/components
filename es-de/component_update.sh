#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.7.0b") == "true" ]]; then
  # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
  # - Expose ES-DE gamelists folder to user at ~/retrodeck/gamelists
  # - Disable ESDE update checks for existing installs
  # - Set ESDE user themes folder directly

  dir_prep "$rdhome/gamelists" "$XDG_CONFIG_HOME/emulationstation/ES-DE/gamelists"

  set_setting_value "$es_settings" "ApplicationUpdaterFrequency" "never" "es_settings"

  rm -rf "$XDG_CONFIG_HOME/emulationstation/ES-DE/gamelists/tools/"

  set_setting_value "$es_settings" "ROMDirectory" "$roms_folder" "es_settings"
  set_setting_value "$es_settings" "MediaDirectory" "$media_folder" "es_settings"
  sed -i '$ a <string name="UserThemeDirectory" value="" />' "$es_settings" # Add new default line to existing file
  set_setting_value "$es_settings" "UserThemeDirectory" "$themes_folder" "es_settings"
  unlink "$XDG_CONFIG_HOME/emulationstation/ROMs"
  unlink "$XDG_CONFIG_HOME/emulationstation/ES-DE/downloaded_media"
  unlink "$XDG_CONFIG_HOME/emulationstation/ES-DE/themes"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.7.3b") == "true" ]]; then
  # In version 0.7.3b, there was a bug that prevented the correct creations of the roms/system folders, so we force recreate them.
  emulationstation --home "$XDG_CONFIG_HOME/emulationstation" --create-system-dirs
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.8.0b") == "true" ]]; then
  log i "In version 0.8.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:"
  log i "- The following components are been added and need to be initialized: es-de 3.0, MAME-SA, Vita3K, GZDoom"

  # in 3.0 .emulationstation was moved into ES-DE
  log i "Renaming old \"$XDG_CONFIG_HOME/emulationstation\" folder as \"$XDG_CONFIG_HOME/ES-DE\""
  mv -f "$XDG_CONFIG_HOME/emulationstation" "$XDG_CONFIG_HOME/ES-DE"

  prepare_component "reset" "es-de"

  log i "New systems were added in this version, regenerating system folders."
  #es-de --home "$XDG_CONFIG_HOME/" --create-system-dirs
  es-de --create-system-dirs
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.8.1b") == "true" ]]; then
  log i "In version 0.8.1b, the following changes were made that required config file updates/reset or other changes to the filesystem:"
  log i "- ES-DE files were moved inside the retrodeck folder, migrating to the new structure"

  log d "ES-DE files were moved inside the retrodeck folder, migrating to the new structure"
  dir_prep "$rdhome/ES-DE/collections" "$XDG_CONFIG_HOME/ES-DE/collections"
  dir_prep "$rdhome/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists"
  log i "Moving ES-DE collections, downloaded_media, gamelist, and themes from \"$rdhome\" to \"$rdhome/ES-DE\""
  set_setting_value "$es_settings" "MediaDirectory" "$rdhome/ES-DE/downloaded_media" "es_settings"
  set_setting_value "$es_settings" "UserThemeDirectory" "$rdhome/ES-DE/themes" "es_settings"
  mv -f "$rdhome/themes" "$rdhome/ES-DE/themes" && log d "Move of \"$rdhome/themes\" in \"$rdhome/ES-DE\" folder completed"
  mv -f "$rdhome/downloaded_media" "$rdhome/ES-DE/downloaded_media" && log d "Move of \"$rdhome/downloaded_media\" in \"$rdhome/ES-DE\" folder completed"
  mv -f "$rdhome/gamelists/"* "$rdhome/ES-DE/gamelists" && log d "Move of \"$rdhome/gamelists/\" in \"$rdhome/ES-DE\" folder completed" && rm -rf "$rdhome/gamelists"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.9.4b") == "true" ]]; then
  # Between updates of ES-DE to 3.2, it looks like some required graphics files may not be created on an existing install
  # We will use rsync to ensure that the shipped graphics and the location ES-DE is looking in are correct
  rsync -rlD --mkpath "/app/retrodeck/graphics/" "/var/config/ES-DE/resources/graphics/"
  dir_prep "$rdhome/ES-DE/gamelists" "$XDG_CONFIG_HOME/ES-DE/gamelists" # Fix broken symlink in case user had moved an ES-DE folder after they were consolidated into ~/retrodeck/ES-DE
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.10.0b") == "true" ]]; then
  # With the RetroDECK Neo the theme folder is changed, so if the user set the RetroDECK Theme we need to fix the name in the config

  if [[ $(get_setting_value "$es_de_config" "Theme" "es_settings") == "retrodeck" ]]; then
    log i "Default RetroDECK theme is set, fixing theme name in ES-DE config."
    set_setting_value "$es_de_config" "Theme" "RetroDECK-theme-main" "es_settings"
  fi
fi

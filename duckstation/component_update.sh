#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.6.2b") == "true" ]]; then
  # In version 0.6.2b, the following changes were made that required config file updates/reset:
  # - Duckstation save and state locations were dir_prep'd to the rdhome/save and /state folders, which was not previously done. Much safer now!

  dir_prep "$rdhome/saves/duckstation" "$XDG_DATA_HOME/duckstation/memcards"
  dir_prep "$rdhome/states/duckstation" "$XDG_DATA_HOME/duckstation/savestates"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.7.0b") == "true" ]]; then
  # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
  # - Update Duckstation configs to latest templates (to accomadate RetroAchievements feature) and move Duckstation config folder from $XDG_DATA_HOME to $XDG_CONFIG_HOME
  # - Move Duckstation saves and states to new locations
  # - Disable ask-on-exit in existing Duckstation installs for proper preset functionality

  dir_prep "$XDG_CONFIG_HOME/duckstation" "$XDG_DATA_HOME/duckstation"
  mv -f "$duckstationconf" "$duckstationconf.bak"
  generate_single_patch "$config/duckstation/settings.ini" "$duckstationconf.bak" "$XDG_CONFIG_HOME/duckstation/duckstation-cheevos-upgrade.patch" pcsx2
  deploy_single_patch "$config/duckstation/settings.ini" "$XDG_CONFIG_HOME/duckstation/duckstation-cheevos-upgrade.patch" "$duckstationconf"
  rm -f "$XDG_CONFIG_HOME/duckstation/duckstation-cheevos-upgrade.patch"

  if [[ -f "$saves_path/duckstation/shared_card_1.mcd" || -f "$saves_path/duckstation/shared_card_2.mcd" ]]; then
    configurator_generic_dialog "RetroDECK 0.7.0b Upgrade" "As part of this update, the location of saves and states for Duckstation has been changed.\n\nYour files will be moved automatically, and can now be found at\n\n~.../saves/psx/duckstation/memcards/\nand\n~.../states/psx/duckstation/"
  fi
  create_dir "$saves_path/psx/duckstation/memcards"
  mv "$saves_path/duckstation/"* "$saves_path/psx/duckstation/memcards/"
  rmdir "$saves_path/duckstation" # File-safe folder cleanup
  unlink "$XDG_CONFIG_HOME/duckstation/memcards"
  set_setting_value "$duckstationconf" "Card1Path" "$saves_path/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
  set_setting_value "$duckstationconf" "Card2Path" "$saves_path/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
  set_setting_value "$duckstationconf" "Directory" "$saves_path/psx/duckstation/memcards" "duckstation" "MemoryCards"
  set_setting_value "$duckstationconf" "RecursivePaths" "$roms_path/psx" "duckstation" "GameList"
  create_dir "$states_path/psx"
  mv -t "$states_path/psx/" "$states_path/duckstation"
  unlink "$XDG_CONFIG_HOME/duckstation/savestates"
  dir_prep "$states_path/psx/duckstation" "$XDG_CONFIG_HOME/duckstation/savestates"

  set_setting_value "$duckstationconf" "SaveStateOnExit" "false" "duckstation" "Main"
  set_setting_value "$duckstationconf" "Enabled" "false" "duckstation" "Cheevos"
fi

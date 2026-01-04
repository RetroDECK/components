#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.10.0b") == "true" ]]; then
  # In version 0.10.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
  # - Init Azahar as it is a new emulator
  # - Migrate legacy Citra saves to Azahar saves dir

  prepare_component "reset" "azahar"
  if [[ -d "$XDG_DATA_HOME/citra-emu/nand" ]]; then
    move "$XDG_DATA_HOME/citra-emu/nand" "$saves_path/n3ds/azahar/"
  fi
  if [[ -d "$XDG_DATA_HOME/citra-emu/sdmc" ]]; then
    move "$XDG_DATA_HOME/citra-emu/sdmc" "$saves_path/n3ds/azahar/"
  fi
  if [[ -d "$saves_path/n3ds/citra/" ]]; then
    move "$saves_path/n3ds/citra/" "$saves_path/n3ds/azahar/"
  fi
  if [[ -d "$mods_path/citra/" ]]; then
    move "$mods_path/citra/" "$mods_path/n3ds/azahar/"
  fi
  if [[ -d "$texture_packs_path/citra/" ]]; then
    move "$texture_packs_path/citra/" "$texture_packs_path/n3ds/azahar/"
  fi
fi

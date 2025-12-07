#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.10.0b") == "true" ]]; then
  # In version 0.10.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
  # - Init Azahar as it is a new emulator
  # - Migrate legacy Citra saves to Azahar saves dir

  prepare_component "reset" "azahar"
  move "$XDG_DATA_HOME/citra-emu/nand" "$saves_path/n3ds/azahar/"
  move "$XDG_DATA_HOME/citra-emu/sdmc" "$saves_path/n3ds/azahar/"
  move "$saves_path/n3ds/citra/" "$saves_path/n3ds/azahar/"
  move "$mods_path/citra/" "$mods_path/n3ds/azahar/"
  move "$texture_packs_path/citra/" "$texture_packs_path/n3ds/azahar/"
  
fi

#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.7.0b") == "true" ]]; then
  # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
  # - Init Cemu as it is a new emulator

  prepare_component "reset" "cemu"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.10.0b") == "true" ]]; then

  prepare_component "postmove" "cemu"

  if [[ -e "$bios_path/cemu/keys.txt" ]]; then
    rm -rf "$XDG_DATA_HOME/Cemu/keys.txt" && ln -s "$bios_path/cemu/keys.txt" "$XDG_DATA_HOME/Cemu/keys.txt" && log d "Linked $bios_path/cemu/keys.txt to $XDG_DATA_HOME/Cemu/keys.txt"
  fi
fi

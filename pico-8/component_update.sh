#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.6.2b") == "true" ]]; then
  # In version 0.6.2b, the following changes were made that required config file updates/reset:
  # - Fix PICO-8 folder structure. ROM and save folders are now sane and binary files will go into ~/retrodeck/bios/pico-8/

  mv "$bios_folder/pico8" "$bios_folder/pico8_olddata" # Move legacy (and incorrect / non-functional ) PICO-8 location for future cleanup / less confusion
  dir_prep "$bios_folder/pico-8" "$HOME/.lexaloffle/pico-8" # Store binary and config files together. The .lexaloffle directory is a hard-coded location for the PICO-8 config file, cannot be changed
  dir_prep "$roms_folder/pico8" "$bios_folder/pico-8/carts" # Symlink default game location to RD roms for cleanliness (this location is overridden anyway by the --root_path launch argument anyway)
  dir_prep "$bios_folder/pico-8/cdata" "$saves_folder/pico-8" # PICO-8 saves folder
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.6.3b") == "true" ]]; then
  # In version 0.6.3b, the following changes were made that required config file updates/reset:
  # - Fix symlink to hard-coded PICO-8 config folder (dir_prep doesn't like ~)

  rm -rf "$HOME/~/" # Remove old incorrect location from 0.6.2b
  rm -f "$HOME/.lexaloffle/pico-8" # Remove old symlink to prevent recursion
  dir_prep "$bios_folder/pico-8" "$HOME/.lexaloffle/pico-8" # Store binary and config files together. The .lexaloffle directory is a hard-coded location for the PICO-8 config file, cannot be changed
  dir_prep "$saves_folder/pico-8" "$bios_folder/pico-8/cdata" # PICO-8 saves folder structure was backwards, fixing for consistency.
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.7.0b") == "true" ]]; then
  # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
  # - Init PICO-8 as it has newly-shipped config files

  prepare_component "reset" "pico8"
fi

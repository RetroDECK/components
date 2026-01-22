#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.9.0b") == "true" ]]; then
  # New components preparation
  log i "New components were added in this version, initializing them"
  prepare_component "reset" "steam-rom-manager"
fi

#######################################
# These actions happen at every update
#######################################

if [[ ! -z $(find "$HOME/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf") || ! -z $(find "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf") ]]; then # If RetroDECK controller profile has been previously installed
  install_retrodeck_controller_profile
fi

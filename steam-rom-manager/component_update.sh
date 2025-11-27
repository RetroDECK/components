#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.9.0b") == "true" ]]; then
  # New components preparation
  log i "New components were added in this version, initializing them"
  prepare_component "reset" "steam-rom-manager"
fi

#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.8.0b") == "true" ]]; then
  log i "- The following components are been added and need to be initialized: es-de 3.0, MAME-SA, Vita3K, GZDoom"

  prepare_component "reset" "gzdoom"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.10.0b") == "true" ]]; then

  log i "0.10.0b Upgrade - Reset: GZDoom"

  prepare_component "reset" "gzdoom"

  # GZDOOM needs to be reset as the changes are in the config that connects to the new folders.
fi

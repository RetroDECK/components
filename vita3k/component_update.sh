#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.8.0b") == "true" ]]; then
  log i "In version 0.8.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:"
  log i "- The following components are been added and need to be initialized: es-de 3.0, MAME-SA, Vita3K, GZDoom"

  prepare_component "reset" "vita3k"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.8.2b") == "true" ]]; then
  log i "Vita3K changed some paths, reflecting them: moving \"$XDG_DATA_HOME/Vita3K\" in \"$XDG_CONFIG_HOME/Vita3K\""
  move "$XDG_DATA_HOME/Vita3K" "$XDG_CONFIG_HOME/Vita3K"
fi

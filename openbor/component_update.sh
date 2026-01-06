#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.10.0b") == "true" ]]; then
  # In version 0.10.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
  # - Init OpenBOR as it is a new emulator

  log i "0.10.0b Upgrade - Reset: OpenBOR"

  prepare_component "reset" "openbor"
fi

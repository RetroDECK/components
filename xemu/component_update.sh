#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################


if [[ $(check_version_is_older_than "$version_being_updated" "0.10.0b") == "true" ]]; then
  log i "0.10.0b Upgrade - Postmove: xemu - Folder Creation"

  create_dir "$screenshots_path/xemu"
  prepare_component "postmove" "xemu"
fi

#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.10.1b") == "true" ]]; then

  log i "0.10.1b Upgrade - Fix Bios Path: MelonDS"

  set_setting_value "$melonds_config" "BIOS9Path" "$bios_path/bios9.bin" "DS" "melonds"
  set_setting_value "$melonds_config" "BIOS7Path" "$bios_path/bios7.bin" "DS" "melonds"
  set_setting_value "$melonds_config" "FirmwarePath" "$bios_path/firmware.bin" "DS" "melonds"

fi

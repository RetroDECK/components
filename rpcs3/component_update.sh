#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.7.0b") == "true" ]]; then
  # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
  # - Update RPCS3 vfs file contents. migrate from old location if needed

  cp -f "$config/rpcs3/vfs.yml" "$XDG_CONFIG_HOME/rpcs3/vfs.yml"
  sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$bios_path/rpcs3/"'^' "$rpcs3vfsconf"
  set_setting_value "$rpcs3vfsconf" "/games/" "$roms_path/ps3/" "rpcs3"
  if [[ -d "$roms_path/ps3/emudir" ]]; then # The old location exists, meaning the emulator was run at least once.
    mkdir "$bios_path/rpcs3"
    mv "$roms_path/ps3/emudir/"* "$bios_path/rpcs3/"
    rm "$roms_path/ps3/emudir"
    configurator_generic_dialog "RetroDECK 0.7.0b Upgrade" "As part of this update and due to a RPCS3 config upgrade, the files that used to exist at\n\n~/retrodeck/roms/ps3/emudir\n\nare now located at\n\n~/retrodeck/bios/rpcs3.\nYour existing files have been moved automatically."
  fi
  create_dir "$storage_path/rpcs3/dev_hdd0"
  create_dir "$storage_path/rpcs3/dev_hdd1"
  create_dir "$storage_path/rpcs3/dev_flash"
  create_dir "$storage_path/rpcs3/dev_flash2"
  create_dir "$storage_path/rpcs3/dev_flash3"
  create_dir "$storage_path/rpcs3/dev_bdvd"
  create_dir "$storage_path/rpcs3/dev_usb000"
  dir_prep "$saves_path/ps3/rpcs3" "$storage_path/rpcs3/dev_hdd0/home/00000001/savedata"
  dir_prep "$states_path/ps3/rpcs3" "$XDG_CONFIG_HOME/rpcs3/savestates"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.8.0b") == "true" ]]; then
  log i "In version 0.8.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:"

  # The save folder of rpcs3 was inverted so we're moving the saves into the real one
  log i "RPCS3 saves needs to be migrated, executing."
  if [[ "$(ls -A "$bios_path/rpcs3/dev_hdd0/home/00000001/savedata")" ]]; then
    log i "Existing RPCS3 savedata found, backing up..."
    create_dir "$backups_folder"
    zip -rq9 "$backups_folder/$(date +"%0m%0d")_rpcs3_save_data.zip" "$bios_path/rpcs3/dev_hdd0/home/00000001/savedata"
  fi
  dir_prep "$saves_path/ps3/rpcs3" "$bios_path/rpcs3/dev_hdd0/home/00000001/savedata"
  log i "RPCS3 saves migration completed, a backup was made here: \"$backups_folder/$(date +"%0m%0d")_rpcs3_save_data.zip\"."
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.10.0b") == "true" ]]; then

  create_dir "$storage_path/rpcs3/dev_hdd0"
  create_dir "$storage_path/rpcs3/dev_hdd1"
  create_dir "$storage_path/rpcs3/dev_flash"
  create_dir "$storage_path/rpcs3/dev_flash2"
  create_dir "$storage_path/rpcs3/dev_flash3"
  create_dir "$storage_path/rpcs3/dev_bdvd"
  create_dir "$storage_path/rpcs3/dev_usb000"

  prepare_component "postmove" "rpcs3"

  # Since in 0.10.0b we added the storage folder we need to migrate the folders

  move "$bios_folder/rpcs3/dev_hdd0" "$storage_path/rpcs3/dev_hdd0"
  move "$bios_folder/rpcs3/dev_hdd1" "$storage_path/rpcs3/dev_hdd1"
  move "$bios_folder/rpcs3/dev_flash" "$storage_path/rpcs3/dev_flash"
  move "$bios_folder/rpcs3/dev_flash2" "$storage_path/rpcs3/dev_flash2"
  move "$bios_folder/rpcs3/dev_flash3" "$storage_path/rpcs3/dev_flash3"
  move "$bios_folder/rpcs3/dev_bdvd" "$storage_path/rpcs3/dev_bdvd"
  move "$bios_folder/rpcs3/dev_usb000" "$storage_path/rpcs3/dev_usb000"

fi

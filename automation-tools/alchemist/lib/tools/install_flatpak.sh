#!/bin/bash

install_flatpak() {
  local flatpak_id="$1"
  local flatpak_version="$2"
  local flatpak_install_mode="$3"
  local flatpak_source_type="$4"

  if ! flatpak remote-add --$flatpak_install_mode --if-not-exists flathub "$FLATHUB_REPO"; then # Ensure flathub is added as a remote
    log error "FlatHub could not be added as a remote"
    return 1
  fi

  if [[ ! -n "$flatpak_version" ]]; then
    log error "Flatpak version not defined"
    return 1
  fi

  if [[ "$flatpak_source_type" == "app" ]]; then
    flatpak_install_cmd() {
      flatpak install --"$1" -y --noninteractive flathub "$2"
      flatpak update --"$1" -y --noninteractive --commit="$3" "$2"
    }
  elif [[ "$flatpak_source_type" == "runtime" ]]; then # Is a flatpak runtime
    flatpak_install_cmd() {
      flatpak install --"$1" -y --or-update --noninteractive flathub "$2//$3"
    }
  else
    log error "Flatpak source type \"$flatpak_source_type\" is invalid"
    return 1
  fi

  if ! flatpak_install_cmd "$flatpak_install_mode" "$flatpak_id" "$flatpak_version"; then
    log error "Flatpak $flatpak_id version $flatpak_version could not be installed."
    return 1
  fi

  return 0
}

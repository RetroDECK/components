#!/bin/bash

# Get the latest release version from Flathub
# USAGE: get_latest_flatpak_release_version <flatpak id>
# RETURNS: version commit hash
get_latest_flatpak_release_version() {
  local flatpak_id="$1"

  local response
  response=$(flatpak remote-info --"$FLATPAK_DEFAULT_INSTALL_MODE" flathub "$flatpak_id" 2>&1)
  local flatpak_cmd_exit=$?

  if [[ "$flatpak_cmd_exit" -ne 0 ]]; then
    log_error "Failed to fetch latest release for $flatpak_id"
    return 1
  fi

  local version
  version=$(echo "$response" | grep -E 'Commit:|Incheckning:' | awk '{print $2}')

  if [[ -z "$version" ]]; then
    log_error "Could not parse latest version flatpak remote-info command"
    return 1
  fi

  echo "$version"
  return 0
}

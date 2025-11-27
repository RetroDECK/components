#!/bin/bash

export FLATPAK_USER_ROOT="$HOME/.local/share/flatpak"
export FLATPAK_SYSTEM_ROOT="/var/lib/flatpak"
export FLATPAK_DEFAULT_INSTALL_MODE="user"
export FLATHUB_REPO="https://flathub.org/repo/flathub.flatpakrepo"
export DEFAULT_WORKDIR="$(mktemp -d)"
export DESIRED_VERSIONS="$SCRIPT_DIR/desired_versions.sh"

#!/bin/bash

source "automation-tools/utils.sh"

grab flatpak_artifacts "https://github.com/RetroDECK/ES-DE/releases/latest/download/RetroDECK-ES-DE-Artifact.tar.gz"

# custom commnads goes here

# TODO: adapt the paths to the new NEO pathing scheme
# RetroDECK Theme
log i "Downloading RetroDECK theme..." "$logfile"
git clone --depth 1 "https://github.com/RetroDECK/RetroDECK-theme" "$WORK_DIR/themes"

finalize
#!/bin/bash

source "automation-tools/assembler.sh"

grab flatpak_id org.DolphinEmu.dolphin-emu

# custom commands goes here

# Universal Dynamic Input for Dolphin and Primehack
log i "Downloading Universal Dynamic Input textures for Dolphin and PrimeHack..." "$logfile"
git clone --depth 1 "https://github.com/Venomalia/UniversalDynamicInput.git" "$WORK_DIR/DynamicInputTextures"

finalize
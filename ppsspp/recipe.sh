#!/bin/bash

source "automation-tools/assembler.sh"

assemble flatpak_id "org.ppsspp.PPSSPP"

# Custom Commands

# PPSSPP Assets
mkdir -p "$component/artifacts/bin/assets"
cp -rf "$WORK_DIR/share/ppsspp/assets/"* "$component/artifacts/bin/assets/"

# PPSSPP BIOS
log i "Downloading PPSSPP BIOS..." "$logfile"
wget "https://github.com/hrydgard/ppsspp/archive/refs/heads/master.zip" -O "$WORK_DIR/ppsspp-bios.zip"
unzip -o "$WORK_DIR/ppsspp-bios.zip" -d "$WORK_DIR/ppsspp-bios"
mkdir -p "$component/artifacts/ppsspp-bios/"
cp -rf "$WORK_DIR/ppsspp-bios/ppsspp-master/assets/PPSSPP"/* "$component/artifacts/ppsspp-bios/"

# PPSSPP Cheats
log i "Downloading PPSSPP cheat database..." "$logfile"
mkdir -p "$component/artifacts/cheats"
wget -O "$component/artifacts/cheats/cheat.db" https://github.com/Saramagrean/CWCheat-Database-Plus-/raw/master/cheat.db

finalize

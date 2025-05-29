#!/bin/bash

source "automation-tools/assembler.sh"

grab flatpak_id "org.ppsspp.PPSSPP"

# PPSSPP Assets
mv "$WORK_DIR/share/ppsspp/assets" "$component/artifacts/"

# PPSSPP BIOS
log i "Downloading PPSSPP BIOS..." "$logfile"
wget "https://github.com/hrydgard/ppsspp/archive/refs/heads/master.zip" -O "$WORK_DIR/ppsspp-bios.zip"
unzip -o "$WORK_DIR/ppsspp-bios.zip" -d "$WORK_DIR/ppsspp-bios"
mkdir -p "$WORK_DIR/ppsspp-bios/assets/PPSSPP"
cp -rf "$WORK_DIR/ppsspp-bios/ppsspp-master/assets/PPSSPP"/* "$WORK_DIR/ppsspp-bios/assets/PPSSPP/"
rm -f "$WORK_DIR/ppsspp-bios.zip"
rm -rf "$WORK_DIR/ppsspp-bios"

# PPSSPP Cheats
log i "Downloading PPSSPP cheat database..." "$logfile"
wget -O "$WORK_DIR/cheat.db" https://github.com/Saramagrean/CWCheat-Database-Plus-/raw/master/cheat.db

finalize

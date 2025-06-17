#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://github.com/PCSX2/pcsx2/releases/latest/download/pcsx2-*-linux-appimage-x64-Qt.AppImage"

# Custom Commands

# PCSX2 Cheats
log i "Downloading PCSX2 cheat database..." "$logfile"
git clone --depth 1 "https://github.com/xs1l3n7x/pcsx2_cheats_collection.git" "$WORK_DIR/pcsx2_cheats_collection"
mkdir -p "$WORK_DIR/pcsx2_cheats"
tar -czf "$WORK_DIR/pcsx2_cheats/pcsx2.tar.gz" -C "$extras/cheats" .

finalize

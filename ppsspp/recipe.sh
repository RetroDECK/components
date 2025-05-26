#!/bin/bash

source "automation-tools/utils.sh"

grab flatpak_id "org.ppsspp.PPSSPP"

log i "Injecting PPSSPP cheat database..." "$logfile"
wget -O "$WORK_DIR/cheat.db" https://github.com/Saramagrean/CWCheat-Database-Plus-/raw/master/cheat.db

finalize

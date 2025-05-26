#!/bin/bash

source "automation-tools/utils.sh"

grab flatpak_id "org.ppsspp.PPSSPP"

log i "Injecting PPSSPP cheat database..." "$logfile"
wget https://github.com/Saramagrean/CWCheat-Database-Plus-/blob/master/cheat.db
mv cheat.db "$component/artifacts/.tmp/"

finalize

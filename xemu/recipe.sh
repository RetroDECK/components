#!/bin/bash

source "automation-tools/utils.sh"

grab appimage "https://github.com/xemu-project/xemu/releases/latest/download/xemu-*-x86_64.AppImage"

# custom commands goes here

# xemu Dummy Hdd
log i "Downloading XEMU dummy HDD..." "$logfile"
wget "https://github.com/mborgerson/xemu-hdd-image/releases/latest/download/xbox_hdd.qcow2.zip" -O "$WORK_DIR/xbox_hdd.qcow2.zip"
unzip -o "$WORK_DIR/xbox_hdd.qcow2.zip" -d "$WORK_DIR/"
cp -f "$WORK_DIR/xbox_hdd.qcow2" "$WORK_DIR/extras/xbox_hdd.qcow2"
rm -f "$WORK_DIR/xbox_hdd.qcow2.zip"

finalize
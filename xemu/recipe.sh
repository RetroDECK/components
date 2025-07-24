#!/bin/bash

source "automation-tools/assembler.sh"

artifacts_dir="$component/artifacts"

assemble appimage "https://github.com/xemu-project/xemu/releases/latest/download/xemu-*-x86_64.AppImage"

# Custom Commands
extras="$artifacts_dir/rd_extras"
mkdir -p "$extras"

# xemu Dummy Hdd
log i "Downloading XEMU dummy HDD..." "$logfile"
wget "https://github.com/mborgerson/xemu-hdd-image/releases/latest/download/xbox_hdd.qcow2.zip" -O "$WORK_DIR/xbox_hdd.qcow2.zip"
unzip -o "$WORK_DIR/xbox_hdd.qcow2.zip" -d "$WORK_DIR/"
cp -f "$WORK_DIR/xbox_hdd.qcow2" "$component/artifacts/$extras/xbox_hdd.qcow2"

finalize

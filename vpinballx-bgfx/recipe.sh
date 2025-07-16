#!/bin/bash

source "automation-tools/assembler.sh"

assemble gh_latest_release "vpinball/vpinball/VPinballX_BGFX-*-linux-x64-Release.zip"

# Right now they are only on pre-release for BGFX
# gh_latest_release is instructed to fallback to the latest pre-release if no latest tag is found.

# Custom Commands

artifacts_path="$component/artifacts"

tar -xvf $component/artifacts/VPinballX_BGFX-*.tar.gz -C $component/artifacts/
rm -f $component/artifacts/VPinballX_BGFX-*.tar.gz
mkdir $component/artifacts/plugins

# PinMAME
log i "Downloading PinMAME: libpinmame..." "$logfile"
wget "https://github.com/vpinball/pinmame/releases/latest/download/libpinmame-3.7.0-46-2b48173-linux-x64.zip " -O "$WORK_DIR/libpinmame-3.7.0-46-2b48173-linux-x64.zip"
unzip -o "$WORK_DIR/libpinmame-*-linux-x64.zip" -d "$artifacts_path/pinmame/"

log i "Downloading PinMAME: xpinmame..." "$logfile"
wget "https://github.com/vpinball/pinmame/releases/latest/download/xpinmame-3.7.0-46-2b48173-linux-x64.zip" -O "$WORK_DIR/xpinmame-3.7.0-46-2b48173-linux-x64.zip"
unzip -o "$WORK_DIR/xpinmame-*-linux-x64.zip" -d "$artifacts_path/pinmame/"

finalize

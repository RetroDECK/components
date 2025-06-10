#!/bin/bash

source "automation-tools/assembler.sh"

assemble gh_latest_release "vpinball/vpinball/VPinballX_BGFX-*-linux-x64-Release.zip"

# Right now they are only on pre-release for BGFX
# gh_latest_release is instructed to fallback to the latest pre-release if no latest tag is found.

# Custom Commands

artifacts_dir="$component/artifacts"

tar -xvf $component/artifacts/VPinballX_BGFX-*.tar.gz -C $component/artifacts/
rm -f $component/artifacts/VPinballX_BGFX-*.tar.gz
mkdir $component/artifacts/Plugins

# PinMAME
log i "Downloading PinMAME: libpinmame..." "$logfile"
wget "https://github.com/vpinball/pinmame/releases/latest/download/libpinmame-3.6.0-1227-ecd032e-linux-x64.zip" -O "$WORK_DIR/libpinmame-3.6.0-1227-ecd032e-linux-x64.zip"
unzip -o "$WORK_DIR/libpinmame-*-linux-x64.zip" -d "$artifacts_dir/pinmame/"

finalize

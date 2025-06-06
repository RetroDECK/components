#!/bin/bash

source "automation-tools/assembler.sh"

assemble gh_latest_release "vpinball/vpinball/VPinballX_BGFX-*-linux-x64-Release.zip"

# Right now they are only on pre-release for BGFX
# gh_latest_release is instructed to fallback to the latest pre-release if no latest tag is found.

# Custom Commands

tar -xvf $component/artifacts/VPinballX_BGFX-*.tar.gz -C $component/artifacts/
rm -f $component/artifacts/VPinballX_BGFX-*.tar.gz
mkdir $component/artifacts/Plugins

finalize

#!/bin/bash

source "automation-tools/assembler.sh"

assemble generic "https://github.com/vpinball/vpinball/releases/download/v10.8.1-3155-8054cc2/VPinballX_BGFX-10.8.1-3155-8054cc2-linux-x64-Release.zip"

# "https://github.com//vpinball/vpinball/releases/latest/download/VPinballX_BGFX-*-linux-x64-Release.zip"

## Right now they are only on pre-release for BGFX we update to above later pathing later.

# Custom Commands

unzip VPinballX_BGFX-*-linux-x64-Release.zip
rm -f VPinballX_BGFX-*-linux-x64-Release.zip
tar -xvf VPinballX_BGFX-*-linux-x64-Release.tar.gz
rm -f VPinballX_BGFX-*-linux-x64-Release.tar.gz
cp -f * $component/artifacts/

finalize

#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://make.mudlet.org/snapshots/ac8fcb/Mudlet-4.19.1-ptb-2025-06-02-52436899-linux-x64.AppImage.tar"

# Custom Commands

tar -xvf Mudlet-*-linux-x64.AppImage.tar

finalize

#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://github.com/RPCS3/rpcs3-binaries-linux/releases/latest/download/rpcs3*.AppImage"

# Custom Commands

finalize

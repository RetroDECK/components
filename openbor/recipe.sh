#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://github.com/DCurrent/openbor/releases/latest/download/OpenBOR-Linux-x64-*.AppImage"

# Custom Commands

finalize

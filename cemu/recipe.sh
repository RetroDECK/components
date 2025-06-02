#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://github.com/cemu-project/Cemu/releases/latest/download/Cemu-*-x86_64.AppImage"

# Custom Commands

# This component appears to run fine with only this library included, so removing all others to save on space
find cemu/lib/ -not -name 'libGLU.so.1' -delete

finalize

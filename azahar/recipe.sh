#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://github.com/azahar-emu/azahar/releases/latest/download/azahar.AppImage"

# Custom Commands

finalize

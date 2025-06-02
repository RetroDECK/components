#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://github.com/SteamGridDB/steam-rom-manager/releases/latest/download/Steam-ROM-Manager-*.AppImage"

# Custom Commands

finalize

#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://github.com/flegald/GZDeck/releases/latest/download/GZDeck*.AppImage"

# Custom Commands

finalize

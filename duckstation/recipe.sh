#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://github.com/RetroDECK/Duckstation/releases/download/preview/DuckStation-x64.AppImage"

# Custom Commands

finalize

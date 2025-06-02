#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://github.com/Vita3K/Vita3K/releases/download/continuous/Vita3K-x86_64.AppImage"

# Custom Commands

finalize

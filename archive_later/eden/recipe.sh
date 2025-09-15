#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://github.com/eden-emulator/Releases/releases/latest/download/Eden-Linux-v*-amd64.AppImage"

# Custom Commands

finalize

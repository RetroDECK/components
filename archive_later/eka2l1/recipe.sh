#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://github.com/EKA2L1/EKA2L1/releases/latest/download/EKA2L1-Linux-x86_64.AppImage"

# Custom Commands

finalize

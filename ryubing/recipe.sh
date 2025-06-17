#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://git.ryujinx.app/api/v4/projects/1/packages/generic/Ryubing/*/ryujinx-*-x64.AppImage"

# Custom Commands

finalize

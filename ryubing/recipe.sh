#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://git.ryujinx.app/api/v4/projects/1/packages/generic/Ryubing/1.3.2/ryujinx-1.3.2-x64.AppImage"

# Custom Commands

finalize

#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://github.com/lindbergh-loader/lindbergh-loader/releases/latest/download/lindbergh-loader.AppImage"

# Custom Commands

finalize

#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://downloads.solarus-games.org/solarus/linux/solarus-launcher-v2.0.1-linux-amd64.zip"

# Custom Commands

finalize

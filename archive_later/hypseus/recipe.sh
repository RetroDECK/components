#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://github.com/DirtBagXon/hypseus-singe/releases/latest/download/hypseus-singe_v2.11.5_SteamOS_ES-DE.tar.gz"

# Custom Commands

finalize

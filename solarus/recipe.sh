#!/bin/bash

source "automation-tools/assembler.sh"

#assemble flatpak_id "https://github.com/flathub/org.solarus_games.solarus.Launcher"

assemble flatpak_id "org.solarus_games.solarus.Launcher"

# Custom Commands

finalize

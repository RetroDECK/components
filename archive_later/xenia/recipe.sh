#!/bin/bash

source "automation-tools/assembler.sh"

assemble gh_latest_release "xenia-canary/xenia-canary-releases/xenia_canary_linux.tar.gz"

touch "$component/artifacts/portable.txt"

# Custom Commands

# Creating a symlink to be used later
ln -s "$XDG_CONFIG_HOME/xenia" "$component/artifacts/portable"

finalize

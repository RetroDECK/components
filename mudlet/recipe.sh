#!/bin/bash

source "automation-tools/assembler.sh"

# URL is a redirect, so we need to resolve it
resolved_url=$(curl -L -o /dev/null -w '%{url_effective}' https://www.mudlet.org/download/42)

assemble appimage "https://github.com/RetroDECK/components/raw/refs/heads/cooker/archive_sources/Mudlet%204.19.1.AppImage"

# Custom Commands

# Creating a symlink to be used later
ln -s "$XDG_CONFIG_HOME/mudlet" "$component/artifacts/portable"

touch "$component/artifacts/portable.txt"

finalize

#!/bin/bash

source "automation-tools/assembler.sh"

# URL is a redirect, so we need to resolve it
resolved_url=$(curl -L -o /dev/null -w '%{url_effective}' https://www.mudlet.org/download/42)

assemble appimage "$resolved_url"

# Custom Commands

touch "$component/artifacts/portable.txt"

finalize

#!/bin/bash

source "automation-tools/assembler.sh"

assemble gh_latest_release "RetroDECK/XRoar"

# Custom Commands

mv "$component/artifacts/bin/xroar" "$component/artifacts/xroar"
rm -rf "$component/artifacts/share" "$component/artifacts/bin"
chmod +x "$component/artifacts/xroar"

finalize

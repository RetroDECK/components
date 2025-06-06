#!/bin/bash

source "automation-tools/assembler.sh"

assemble gh_latest_release "RetroDECK/XRoar"

# Custom Commands

chmod +x "$component/artifacts/xroar"

finalize

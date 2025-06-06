#!/bin/bash

source "automation-tools/assembler.sh"

assemble gh_latest_release "xenia-canary/xenia-canary-releases/xenia_canary_linux.tar.gz"

# Custom Commands

finalize

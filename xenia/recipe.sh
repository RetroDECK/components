#!/bin/bash

source "automation-tools/assembler.sh"

assemble generic "https://github.com/xenia-canary/xenia-canary-releases/releases/latest/download/xenia_canary_linux.tar.gz"

# Custom Commands

tar -xvf xenia_canary_linux.tar.gz
rm -f xenia_canary_linux.tar.gz
cp -f * $component/artifacts/

finalize

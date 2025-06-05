#!/bin/bash

source "automation-tools/assembler.sh"

assemble generic "https://github.com/xenia-canary/xenia-canary-releases/releases/latest/download/xenia_canary_linux.tar.gz"

# Custom Commands

tar -xvf xenia/artifacts/xenia.tar.gz
rm -f xenia/artifacts/xenia.tar.gz
cp -f * $component/artifacts/

finalize

#!/bin/bash

source "automation-tools/assembler.sh"

grab generic "https://github.com/RetroDECK/Pancakes-bin/releases/latest/download/pancakes-Release-linux_x64.tar.gz"
rm -rf pancakes.tar.gz
shopt -s dotglob
mv "$WORK_DIR/publish/"* "$WORK_DIR/"
shopt -u dotglob
rm -rf publish

finalize
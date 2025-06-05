#!/bin/bash

source "automation-tools/assembler.sh"

assemble generic "https://github.com/user-attachments/files/20605948/xroar.zip"

# Custom Commands

unzip xroar.zip
rm -f xroar.zip
cp -f * $component/artifacts/

finalize

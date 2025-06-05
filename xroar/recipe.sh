#!/bin/bash

source "automation-tools/assembler.sh"

assemble generic "https://github.com/user-attachments/files/20533904/xroarbinary.zip"

# Custom Commands

unzip xroarbinary.zip
rm -f xroarbinary.zip
cp -f * $component/artifacts/

finalize

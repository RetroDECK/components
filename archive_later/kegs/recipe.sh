#!/bin/bash

source "automation-tools/assembler.sh"

assemble generic "https://kegs.sourceforge.net/kegs.1.38.zip"

# Custom Commands

artifacts_path="$component/artifacts"

unzip $component/artifacts/kegs.1.38.zip
mv $component/artifacts/kegs.1.38/* $component/artifacts/
rmdir $component/artifacts/kegs.1.38/
rm -f $component/artifacts/kegs.1.38.zip
rm -f $component/artifacts/kegswin.exe

finalize

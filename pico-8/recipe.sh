#!/bin/bash

# Just a dummy recipe to make the component assemblation work.

source "automation-tools/assembler.sh"

assemble local "$component/component_launcher.sh"

finalize
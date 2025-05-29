#!/bin/bash

# This recipe differs fomr the standard as PortMaster needs a special setup

source "automation-tools/assembler.sh"
WORK_DIR=$(mktemp -d)
component="portmaster"

wget -qc "https://github.com/PortsMaster/PortMaster-GUI/releases/latest/download/retrodeck.portmaster.zip" -O "$WORK_DIR/PortMaster.zip"

# Adding an additional launcher for harbourmaster
echo '#!/bin/bash' > "$WORK_DIR/harbourmaster"
echo "\"/var/data/PortMaster/harbourmaster\" \"$@\"" >> "$WORK_DIR/harbourmaster"
chmod +x "$WORK_DIR/harbourmaster"

log d "Listing WORK_DIR ($WORK_DIR)"
ls -lah "$WORK_DIR"

finalize
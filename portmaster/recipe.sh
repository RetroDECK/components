#!/bin/bash

# This recipe differs fomr the standard as PortMaster needs a special setup

source "automation-tools/assembler.sh"
WORK_DIR=$(mktemp -d)

wget -qc "https://github.com/PortsMaster/PortMaster-GUI/releases/latest/download/retrodeck.portmaster.zip" -O "$WORK_DIR/$EXTRAS/PortMaster.zip"

# Adding an additional launcher for harbourmaster
echo '#!/bin/bash' > "$WORK_DIR/$EXTRAS/harbourmaster"
echo "\"/var/data/PortMaster/harbourmaster\" \"$@\"" >> "$WORK_DIR/$EXTRAS/harbourmaster"
chmod +x "$WORK_DIR/$EXTRAS/harbourmaster"

finalize
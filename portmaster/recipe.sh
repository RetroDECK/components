#!/bin/bash

# This recipe differs fomr the standard as PortMaster needs a special setup

source "automation-tools/utils.sh"

wget -qc "https://github.com/PortsMaster/PortMaster-GUI/releases/latest/download/retrodeck.portmaster.zip" -O "$WORK_DIR/extras/PortMaster.zip"

# Adding an additional launcher for harbourmaster
echo '#!/bin/bash' > "$WORK_DIR/extras/harbourmaster"
echo "\"/var/data/PortMaster/harbourmaster\" \"$@\"" >> "$WORK_DIR/extras/harbourmaster"
chmod +x "$WORK_DIR/extras/harbourmaster"

finalize
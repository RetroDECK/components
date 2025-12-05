#!/usr/bin/env bash
set -euo pipefail

# Smoke test: verify run_game.bat is created with CRLF endings by create_launcher_bat

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Provide minimal environment for the function
export GAME_PATH="Rages of Mages II.exe"
LAUNCHER_DIR="$tmpdir/launcher"
mkdir -p "$LAUNCHER_DIR"

# Minimal stub for logging used by the script functions
log() { :; }

# Source the script (this will NOT call main because of guard added)
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# When sourcing, disable 'set -u' to avoid unbound-variable errors for optional runtime
# variables in the module. Re-enable afterwards.
set +u
source "$script_dir/winplay.sh"
set -u

# Run the function
create_launcher_bat "$LAUNCHER_DIR"
file="$LAUNCHER_DIR/run_game.bat"

if [[ ! -f "$file" ]]; then
  echo "FAIL: run_game.bat not created"
  exit 2
fi

# Check for CRLF sequences in the file
if hexdump -v -e '1/1 "%02x "' "$file" | grep -q '0d 0a'; then
  echo "PASS: run_game.bat contains CRLF sequences"
  exit 0
else
  echo "FAIL: run_game.bat missing CRLF sequences"
  exit 3
fi

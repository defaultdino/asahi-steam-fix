#!/bin/bash

set -uo pipefail

LIB_DIR="$HOME/.local/lib"
BIN_DIR="$HOME/.local/bin"

files=(
    "$LIB_DIR/muvm-guest-dbus.sh"
    "$LIB_DIR/muvm-dmabuf-fixup.so"
    "$BIN_DIR/steam"
)

for f in "${files[@]}"; do
    if [ -e "$f" ]; then
        rm -f "$f"
        echo "Removed: $f"
    fi
done

echo "Done. 'steam' will now resolve to whichever /usr/bin/steam is next on your PATH."

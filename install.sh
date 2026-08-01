#!/bin/bash

## this script starts a bare D-Bus daemon in the muvm guest (the "Waiting for network" issue in steam)
## and preloads a dmabuf fixup shim (for GPU-related VM crashes)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$HOME/.local/lib"
BIN_DIR="$HOME/.local/bin"

echo "==> Checking prerequisites"
if [ ! -x /usr/bin/steam ]; then
    echo "Fedora 'steam' package not found. Install it first:"
    echo "    sudo dnf install steam"
    exit 1
fi

for tool in gcc patch; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "'$tool' not found. Install it first, e.g.:"
        echo "    sudo dnf install $tool"
        exit 1
    fi
done

mkdir -p "$LIB_DIR" "$BIN_DIR"

echo "==> Installing D-Bus guest bridge"
cp "$SCRIPT_DIR/files/muvm-guest-dbus.sh" "$LIB_DIR/muvm-guest-dbus.sh"
chmod +x "$LIB_DIR/muvm-guest-dbus.sh"

echo "==> Building dmabuf fixup shim"
gcc -shared -fPIC -O2 \
    -o "$LIB_DIR/muvm-dmabuf-fixup.so" \
    "$SCRIPT_DIR/files/muvm-dmabuf-fixup.c" -ldl

echo "==> Patching a local copy of the Steam launcher"
cp /usr/bin/steam "$BIN_DIR/steam"
chmod +x "$BIN_DIR/steam"

if ! (cd "$BIN_DIR" && patch -p3 --dry-run < "$SCRIPT_DIR/files/steam.patch") >/dev/null 2>&1; then
    echo "ERROR: files/steam.patch does not apply cleanly to your /usr/bin/steam"
    echo "Fedora's launcher script may have changed since this patch was written"
    echo
    echo "Patch it manually (see README.md for the diff or open an issue"
    echo "with your /usr/bin/steam contents attached)"
    exit 1
fi

(cd "$BIN_DIR" && patch -p3 < "$SCRIPT_DIR/files/steam.patch")
echo "Patched successfully!"

echo
echo "==> Done"
echo
if command -v steam >/dev/null 2>&1 && [ "$(command -v steam)" = "$BIN_DIR/steam" ]; then
    echo "PATH is set up correctly -- 'steam' resolves to $BIN_DIR/steam."
else
    echo "WARNING: '$BIN_DIR' does not currently precede /usr/bin on your PATH."
    echo "Add this to your shell profile (~/.bashrc / ~/.zshrc), then restart your shell:"
    echo
    echo '    export PATH="$HOME/.local/bin:$PATH"'
fi
echo
echo "Launch with: steam"
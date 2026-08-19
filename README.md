# asahi-steam-fix

includes fixes for running Steam on **Fedora Asahi Remix** on ARM64 architecture Macbooks, getting you past two specific failures the `steam` package hits:

- Steam launches, the client comes up, but it's stuck forever on **"Waiting for network"** even though networking is fine.
- Steam (or muvm) **crashes the VM** with `Failure during vcpu run: Bad address (os error 14)` usually right as Steam touches GPU-related resources.

## Quick install

```bash
sudo dnf install steam
git clone https://github.com/defaultdino/asahi-steam-fix
cd asahi-steam-fix
./install.sh
```

Then confirm `~/.local/bin` comes **before** `/usr/bin` in your `PATH` so that our patched launcher takes precedence over the original

```bash
command -v steam   # should print $HOME/.local/bin/steam
```

Launch normally:

```bash
steam
```

## What it actually does

Two small fixes both applied to the invocation of `muvm` inside Fedora's `/usr/bin/steam` launcher script:

1. **`files/muvm-guest-dbus.sh`** starts a bare system D-Bus daemon inside the muvm guest before Steam launches. Steam reads networkstatus from NetworkManager over D-Bus so the guest has its own `/run` and therefore no system bus by default, so that check never completes and the client sits on "Waiting for network" forever.

2. **`files/muvm-dmabuf-fixup.c`** is a small `LD_PRELOAD` shim that works around a libkrun limitation. libkrun maps GPU blob resources into the guests shared memory window as dma-bufs via `mmap(MAP_FIXED)`. When the guest writes to one the KVM can't fault the page in itself unless the VMM already touched it first, and libkrun doesn't. The fixup touches every page of the relevant dma-buf mappings once without changing its contents, right after `mmap`.

## Uninstall

```bash
./uninstall.sh
```

## Troubleshooting

If you see:

```
ERROR: ld.so: object '.../muvm-dmabuf-fixup.so' from LD_PRELOAD cannot be preloaded (cannot open shared object file): ignored.
```

**this is likely not a real failure**

## Credits

Guest-side fix design (D-Bus bridge, dmabuf preload shim) originally
from [ccharon/muvm-steam-fixes](https://github.com/ccharon/muvm-steam-fixes).
This repo repackages just those two artifacts and wires them into
Fedora's actual launcher script directly, without the Gentoo-specific
wrapper

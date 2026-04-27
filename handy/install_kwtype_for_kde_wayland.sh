#!/usr/bin/env bash
set -euo pipefail

# Build and install KWtype for KDE Plasma Wayland into ~/.local/bin.
# KWtype uses KWin Fake Input and is the right direct-typing helper for KDE Wayland.

SRC_DIR="${SRC_DIR:-$HOME/code/tools/KWtype}"
REPO_URL="${REPO_URL:-https://github.com/Sporif/KWtype.git}"
PREFIX="${PREFIX:-$HOME/.local}"

log() { printf '\n==> %s\n' "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing command: $1"; exit 1; }; }

log "Installing build dependencies"
sudo apt update
sudo apt install -y \
  git build-essential meson ninja-build pkg-config \
  qt6-base-dev qt6-wayland-dev libkf5wayland-dev libwayland-dev libxkbcommon-dev

log "Fetching KWtype"
if [ ! -d "$SRC_DIR/.git" ]; then
  mkdir -p "$(dirname "$SRC_DIR")"
  git clone "$REPO_URL" "$SRC_DIR"
fi
cd "$SRC_DIR"
git fetch --all --prune
git checkout master
git pull --ff-only || true

log "Building"
rm -rf build
meson setup --prefix="$PREFIX" --buildtype=release build
meson compile -C build
meson install -C build

log "Installed"
command -v kwtype || true
"$PREFIX/bin/kwtype" --help 2>/dev/null || true
cat <<MSG

Next:
  export PATH="$PREFIX/bin:\$PATH"
  kwtype "hello from kwtype"

Then set Handy to:
  paste_method=direct
  typing_tool=kwtype (or auto)
MSG

#!/usr/bin/env bash
set -euo pipefail

# Build and install Handy from upstream source on Kubuntu/Ubuntu.
# Safe order: build first, then install the generated .deb over the existing package.

SRC_DIR="${SRC_DIR:-$HOME/code/tools/Handy}"
REPO_URL="${REPO_URL:-https://github.com/cjpais/Handy.git}"
BRANCH_OR_TAG="${1:-${BRANCH_OR_TAG:-main}}"

log() { printf '\n==> %s\n' "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing command: $1"; exit 1; }; }

APT_DEPS=(
  git
  build-essential
  libasound2-dev
  pkg-config
  libssl-dev
  libvulkan-dev
  vulkan-tools
  glslc
  libgtk-3-dev
  libwebkit2gtk-4.1-dev
  libayatana-appindicator3-dev
  librsvg2-dev
  libgtk-layer-shell0
  libgtk-layer-shell-dev
  patchelf
  cmake
  cargo
  rustc
  wtype
  wl-clipboard
)

log "Installing apt build/runtime dependencies"
sudo apt update
sudo apt install -y "${APT_DEPS[@]}"

log "Checking required commands"
need git
need bun
need cargo
need rustc
need dpkg
need apt

log "Source dir: $SRC_DIR"
if [ ! -d "$SRC_DIR/.git" ]; then
  mkdir -p "$(dirname "$SRC_DIR")"
  git clone "$REPO_URL" "$SRC_DIR"
fi

cd "$SRC_DIR"
log "Fetching upstream"
git fetch --all --tags --prune

git checkout "$BRANCH_OR_TAG"
if [ "$BRANCH_OR_TAG" = "main" ] || [ "$BRANCH_OR_TAG" = "master" ]; then
  git pull --ff-only || true
fi

log "Current upstream version"
git --no-pager log --oneline -1

log "Installing JS deps"
bun install

log "Building .deb bundle only"
bun run tauri build -- --bundles deb

DEB=$(find src-tauri/target/release/bundle/deb -maxdepth 1 -type f -name 'Handy_*_amd64.deb' | sort -V | tail -1)
if [ -z "${DEB:-}" ]; then
  echo "ERROR: no Handy amd64 .deb found"
  exit 1
fi

log "Built package"
ls -lh "$DEB"

log "Currently installed Handy"
dpkg -l handy 2>/dev/null || true
command -v handy >/dev/null 2>&1 && handy --help >/dev/null 2>&1 || true

cat <<MSG

Ready to install:
  $DEB

This will install/upgrade the 'handy' package via apt.
MSG

read -r -p "Install this .deb now? [y/N] " ans
case "$ans" in
  y|Y|yes|YES)
    log "Stopping running Handy"
    pkill handy 2>/dev/null || true
    sleep 0.5
    log "Installing"
    sudo apt install "./$DEB"
    log "Installed Handy package"
    dpkg -l handy | grep '^ii' || true
    log "Binary"
    command -v handy
    ;;
  *)
    echo "Skipped install. Package remains at: $DEB"
    ;;
esac

cat <<MSG

Next recommended step for KDE Wayland paste:
  ~/code/tools/linux-kubuntu-tweaks/handy/fix_handy_wayland_paste.sh
  handy --start-hidden
MSG

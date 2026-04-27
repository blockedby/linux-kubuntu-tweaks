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
  libevdev-dev
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
  curl
  autoconf
  automake
  libtool
  wtype
  wl-clipboard
)

log "Installing apt build/runtime dependencies"
sudo apt update
sudo apt install -y "${APT_DEPS[@]}"

export PATH="$HOME/.cargo/bin:$PATH"

log "Checking required commands"
need git
need curl
need dpkg
need apt

if ! command -v rustup >/dev/null 2>&1; then
  log "Installing rustup to ~/.cargo via official rustup-init"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
  export PATH="$HOME/.cargo/bin:$PATH"
  hash -r
fi

need rustup
log "Ensuring modern Rust toolchain via rustup"
rustup toolchain install stable
rustup default stable
hash -r
need cargo
need rustc
log "Using rustc: $(rustc --version)"
log "Using cargo: $(cargo --version)"

if command -v bun >/dev/null 2>&1; then
  BUN_BIN="$(command -v bun)"
elif [ -x "$HOME/.vite-plus/js_runtime/node/24.15.0/lib/node_modules/bun/node_modules/@oven/bun-linux-x64-baseline/bin/bun" ]; then
  BUN_BIN="$HOME/.vite-plus/js_runtime/node/24.15.0/lib/node_modules/bun/node_modules/@oven/bun-linux-x64-baseline/bin/bun"
elif [ -x "$HOME/.vite-plus/js_runtime/node/24.15.0/lib/node_modules/bun/node_modules/@oven/bun-linux-x64-musl/bin/bun" ]; then
  BUN_BIN="$HOME/.vite-plus/js_runtime/node/24.15.0/lib/node_modules/bun/node_modules/@oven/bun-linux-x64-musl/bin/bun"
else
  echo "ERROR: missing command: bun"
  echo "Install Bun or expose VitePlus Bun, e.g.:"
  echo "  ln -sf \"$HOME/.vite-plus/js_runtime/node/24.15.0/lib/node_modules/bun/node_modules/@oven/bun-linux-x64-baseline/bin/bun\" \"$HOME/.local/bin/bun\""
  exit 1
fi
log "Using bun: $BUN_BIN"

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
"$BUN_BIN" install

log "Building .deb bundle only"
"$BUN_BIN" run tauri build --bundles deb

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

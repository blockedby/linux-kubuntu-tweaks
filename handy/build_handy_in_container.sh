#!/usr/bin/env bash
set -euo pipefail

ENGINE="${CONTAINER_ENGINE:-}"
if [ -z "$ENGINE" ]; then
  if command -v podman >/dev/null 2>&1; then ENGINE=podman
  elif command -v docker >/dev/null 2>&1; then ENGINE=docker
  else echo "ERROR: need podman or docker"; exit 1
  fi
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTAINERFILE="$REPO_ROOT/handy/container/Containerfile.handy-build"
IMAGE="${IMAGE:-handy-build:ubuntu24.04}"
SRC_DIR="${SRC_DIR:-$HOME/code/tools/Handy-container-src}"
OUT_DIR="${OUT_DIR:-$HOME/code/tools/handy-build-output}"
TAG="${1:-v0.8.2}"
REPO_URL="${REPO_URL:-https://github.com/cjpais/Handy.git}"

log() { printf '\n==> %s\n' "$*"; }

mkdir -p "$SRC_DIR" "$OUT_DIR"

log "Building container image with $ENGINE"
"$ENGINE" build -t "$IMAGE" -f "$CONTAINERFILE" "$REPO_ROOT"

log "Building Handy $TAG inside container"
"$ENGINE" run --rm \
  -v "$SRC_DIR:/src:Z" \
  -v "$OUT_DIR:/out:Z" \
  "$IMAGE" \
  bash -lc "set -euo pipefail
    export PATH=/root/.cargo/bin:/root/.bun/bin:\$PATH
    if [ ! -d /src/.git ]; then
      git clone '$REPO_URL' /src
    fi
    cd /src
    git fetch --all --tags --prune
    git checkout '$TAG'
    git reset --hard
    rm -rf src-tauri/target/release/bundle/deb/*.deb src-tauri/target/release/build/whisper-rs-sys-* src-tauri/target/release/deps/libwhisper_rs_sys-*
    rustc --version
    cargo --version
    bun --version
    bun install
    set +e
    bun run tauri build --bundles deb
    status=\$?
    set -e
    deb=\$(find src-tauri/target/release/bundle/deb -maxdepth 1 -type f -name 'Handy_*_amd64.deb' | sort -V | tail -1)
    if [ -z \"\$deb\" ]; then
      echo 'ERROR: no deb produced'
      exit \$status
    fi
    cp -f \"\$deb\" /out/
    echo \"Copied \$deb to /out\"
    if [ \$status -ne 0 ]; then
      echo \"WARN: tauri exited with \$status after producing deb, likely signing-key warning\"
    fi
  "

log "Output packages"
ls -lh "$OUT_DIR"/Handy_*_amd64.deb

cat <<MSG

Install manually with:
  sudo apt install "$OUT_DIR"/Handy_*_amd64.deb

Then apply KDE Wayland paste fix:
  ~/code/tools/linux-kubuntu-tweaks/handy/fix_handy_wayland_paste.sh
  handy --start-hidden
MSG

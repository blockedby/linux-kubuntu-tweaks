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
  qtbase5-dev libkf5wayland-dev libwayland-dev libxkbcommon-dev

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
# Ubuntu 24.04 ships KWaylandClient as a KF5/Qt5 library. Upstream KWtype's
# Meson file asks for Qt6 + KWaylandClient, which can build but segfaults from
# Qt6/KF5 ABI mixing. Patch only the local checkout to Qt5 + KF5WaylandClient.
python3 - <<'PY'
from pathlib import Path
p = Path('meson.build')
s = p.read_text()
s = s.replace("qt6 = import('qt6')", "qt5 = import('qt5')")
s = s.replace("qt6_deps = dependency('qt6', modules: ['Core', 'DBus'])", "qt5_deps = dependency('qt5', modules: ['Core', 'DBus'])")
s = s.replace("qtprocessed = qt6.compile_moc(headers: 'src/main.h')", "qtprocessed = qt5.compile_moc(headers: 'src/main.h')")
s = s.replace("qt6_deps,", "qt5_deps,")
s = s.replace("dependency('KWaylandClient')", "dependency('KF5WaylandClient')")
p.write_text(s)

p = Path('src/main.cpp')
s = p.read_text()
s = s.replace('''    if (!QDBusConnection::sessionBus().interface()->isServiceRegistered(
            "org.kde.keyboard")) {
        std::cerr << "Error: org.kde.keyboard DBus service is not available.\\n";
        return 1;
    }
    uint32_t originalLayout = kwinGetLayout();
    uint32_t currentLayout = originalLayout;
''','''    bool hasKwinKeyboardService = QDBusConnection::sessionBus().interface()->isServiceRegistered(
            "org.kde.keyboard");
    if (!hasKwinKeyboardService) {
        std::cerr << "Warning: org.kde.keyboard DBus service is not available; layout switching disabled.\\n";
    }
    uint32_t originalLayout = hasKwinKeyboardService ? kwinGetLayout() : 0;
    uint32_t currentLayout = originalLayout;
''')
s = s.replace('''            if (currentLayout != targetLayout) {
''','''            if (hasKwinKeyboardService && currentLayout != targetLayout) {
''')
s = s.replace('''    if (currentLayout != originalLayout) {
''','''    if (hasKwinKeyboardService && currentLayout != originalLayout) {
''')
p.write_text(s)
PY

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

#!/usr/bin/env bash
set -euo pipefail

# Restore Logitech MX Master 3S thumb gesture button behavior through Solaar.
# Intended for KDE Plasma: hold the thumb gesture button and move the mouse.

SOLAAR_BIN="${SOLAAR_BIN:-$HOME/code/Solaar/.venv/bin/solaar}"
if [[ ! -x "$SOLAAR_BIN" ]]; then
  SOLAAR_BIN="$(command -v solaar || true)"
fi
if [[ -z "${SOLAAR_BIN:-}" || ! -x "$SOLAAR_BIN" ]]; then
  echo "ERROR: solaar not found. Set SOLAAR_BIN=/path/to/solaar" >&2
  exit 1
fi

CONFIG_DIR="$HOME/.config/solaar"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
RULES_FILE="$CONFIG_DIR/rules.yaml"
BACKUP_DIR="$CONFIG_DIR/backups"
STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$CONFIG_DIR" "$BACKUP_DIR"
[[ -f "$CONFIG_FILE" ]] && cp "$CONFIG_FILE" "$BACKUP_DIR/config.yaml.$STAMP.bak"
[[ -f "$RULES_FILE" ]] && cp "$RULES_FILE" "$BACKUP_DIR/rules.yaml.$STAMP.bak"

cat > "$RULES_FILE" <<'YAML'
%YAML 1.3
---
# Existing local shortcut: Smart Shift opens help/shortcut overlay.
- Key: [Smart Shift, pressed]
- KeyPress:
  - [Control_L, Shift_L, question]
  - click
...
---
# Click/release the thumb gesture button without moving: KDE Overview.
- MouseGesture: [Mouse Gesture Button]
- Execute: [qdbus, org.kde.kglobalaccel, /component/kwin, org.kde.kglobalaccel.Component.invokeShortcut, Overview]
...
---
# MX Master 3S: hold thumb gesture button + move left/right to switch desktops.
- MouseGesture: [Mouse Gesture Button, Mouse Left]
- Execute: [qdbus, org.kde.KWin, /KWin, org.kde.KWin.previousDesktop]
...
---
- MouseGesture: [Mouse Gesture Button, Mouse Right]
- Execute: [qdbus, org.kde.KWin, /KWin, org.kde.KWin.nextDesktop]
...
---
# Up is intentionally unassigned for now. Down keeps a handy Show Desktop gesture.
- MouseGesture: [Mouse Gesture Button, Mouse Down]
- Execute: [qdbus, org.kde.KWin, /KWin, org.kde.KWin.showDesktop, "true"]
...
YAML

# Persist the MX Master 3S gesture-button diversion in Solaar's config cache.
# Button ids from `solaar show`: 195 = Mouse Gesture Button, 196 = Smart Shift.
if [[ -f "$CONFIG_FILE" ]]; then
  python3 - <<'PY'
from pathlib import Path
p = Path.home() / '.config/solaar/config.yaml'
s = p.read_text()
repls = {
    'divert-keys: {82: 0, 83: 0, 86: 0, 195: 0, 196: 1}': 'divert-keys: {82: 0, 83: 0, 86: 0, 195: 2, 196: 1}',
    'divert-keys: {82: 0, 83: 0, 86: 0, 195: 1, 196: 1}': 'divert-keys: {82: 0, 83: 0, 86: 0, 195: 2, 196: 1}',
    'divert-keys: {82: 0, 83: 0, 86: 2, 195: 0, 196: 1}': 'divert-keys: {82: 0, 83: 0, 86: 0, 195: 2, 196: 1}',
}
for old, new in repls.items():
    s = s.replace(old, new)
p.write_text(s)
PY
fi

# Try to apply live. Some devices still need a power-cycle/reconnect before active state follows saved state.
"$SOLAAR_BIN" config "MX Master 3S" divert-keys "Mouse Gesture Button" "Mouse Gestures" || true

# Restart Solaar so rules are reloaded.
pkill -f '/solaar|bin/solaar' || true
nohup "$SOLAAR_BIN" --window=hide >/tmp/solaar-restart.log 2>&1 &
sleep 2

echo "Done. Backups are in $BACKUP_DIR"
echo "Test: hold MX Master 3S thumb gesture button and move left/right."
echo "If saved=Mouse Gestures but active is still Diverted, power-cycle the mouse."
"$SOLAAR_BIN" show "MX Master 3S" 2>/dev/null | grep -A3 'Key/Button Diversion' || true

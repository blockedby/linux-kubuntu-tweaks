#!/usr/bin/env bash
set -euo pipefail

SETTINGS="$HOME/.local/share/com.pais.handy/settings_store.json"
BACKUP="$SETTINGS.bak.$(date +%Y%m%d-%H%M%S)"

echo "Handy Wayland paste fixer"
echo

if [ "${XDG_SESSION_TYPE:-}" != "wayland" ]; then
  echo "WARN: current session is not Wayland: XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-unset}"
fi

missing=()
for cmd in wl-copy wl-paste; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("wl-clipboard")
done
command -v wtype >/dev/null 2>&1 || missing+=("wtype")

if [ ${#missing[@]} -gt 0 ]; then
  echo "Missing packages/tools: ${missing[*]}"
  echo "Install with: sudo apt install wtype wl-clipboard"
  exit 1
fi

if [ ! -f "$SETTINGS" ]; then
  echo "ERROR: Handy settings not found: $SETTINGS"
  echo "Start Handy once, then run this script again."
  exit 1
fi

echo "Stopping Handy if running..."
pkill handy 2>/dev/null || true
sleep 0.5

echo "Backup: $BACKUP"
cp "$SETTINGS" "$BACKUP"

python3 - <<'PY'
import json
from pathlib import Path

p = Path.home() / ".local/share/com.pais.handy/settings_store.json"
data = json.loads(p.read_text())
s = data.setdefault("settings", {})

# Wayland-safe insertion: type text directly via wtype instead of Shift+Insert via X11/enigo.
s["paste_method"] = "direct"
s["typing_tool"] = "wtype"

# Toggle mode is more reliable than app-owned push-to-talk on Wayland.
s["push_to_talk"] = False

# Keep model warm; optional but reduces first-use lag.
s["model_unload_timeout"] = "never"

p.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
print("Updated:")
print("  paste_method = direct")
print("  typing_tool   = wtype")
print("  push_to_talk  = false")
PY

echo
echo "Quick manual test: focus a text field, then run:"
echo "  wtype 'hello from wtype'"
echo
echo "Start Handy again with:"
echo "  handy --start-hidden"
echo
echo "If insertion still fails, restore backup:"
echo "  cp '$BACKUP' '$SETTINGS'"

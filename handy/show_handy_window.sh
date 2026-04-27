#!/usr/bin/env bash
set -euo pipefail

settings="$HOME/.local/share/com.pais.handy/settings_store.json"
[ -f "$settings" ] || { echo "Missing Handy settings: $settings" >&2; exit 1; }

python3 - <<'PY'
import json, pathlib, shutil, time
p = pathlib.Path.home() / '.local/share/com.pais.handy/settings_store.json'
b = pathlib.Path(str(p) + '.bak.show-window.' + time.strftime('%Y%m%d-%H%M%S'))
shutil.copy2(p, b)
data = json.loads(p.read_text())
s = data.setdefault('settings', {})
s['start_hidden'] = False
s['show_tray_icon'] = True
# Keep stable clipboard-only mode.
s['paste_method'] = 'none'
s['clipboard_handling'] = 'copy_to_clipboard'
s['typing_tool'] = 'auto'
p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(f'Backup: {b}')
PY

mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/Handy.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=Handy
Comment=Handy startup script
Exec=/usr/bin/handy
StartupNotify=false
Terminal=false
EOF

pkill -x handy 2>/dev/null || true
sleep 1
nohup /usr/bin/handy >/tmp/handy-start.log 2>&1 &
echo "Handy restarted with visible window enabled."

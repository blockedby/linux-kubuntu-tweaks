#!/usr/bin/env bash
set -euo pipefail

settings="$HOME/.local/share/com.pais.handy/settings_store.json"
[ -f "$settings" ] || { echo "Missing Handy settings: $settings" >&2; exit 1; }

python3 - <<'PY'
import json, pathlib, shutil, time
p = pathlib.Path.home() / '.local/share/com.pais.handy/settings_store.json'
b = pathlib.Path(str(p) + '.bak.disable-paste.' + time.strftime('%Y%m%d-%H%M%S'))
shutil.copy2(p, b)
data = json.loads(p.read_text())
s = data.setdefault('settings', {})
# Do not synthesize keys/direct typing. Only keep the transcript available in clipboard.
s['paste_method'] = 'none'
s['clipboard_handling'] = 'copy_to_clipboard'
s['typing_tool'] = 'auto'
s['show_tray_icon'] = True
s['start_hidden'] = True
p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(f'Backup: {b}')
PY

pkill -x handy 2>/dev/null || true
pkill -x wl-copy 2>/dev/null || true
pkill -x kwtype 2>/dev/null || true
sleep 1
nohup /usr/bin/handy --start-hidden >/tmp/handy-start.log 2>&1 &
echo "Handy restarted with auto-paste disabled."

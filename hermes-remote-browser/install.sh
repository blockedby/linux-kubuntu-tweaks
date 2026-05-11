#!/usr/bin/env bash
set -euo pipefail

# Install local headed Chrome + reverse SSH tunnel used by Hermes running on NL-2-NVMe.
# The VPS sees Chrome DevTools at 127.0.0.1:9233 via ssh -R, while Chrome itself
# runs on this desktop so manual login/2FA/intervention remains possible.

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.config/systemd/user" "$HOME/Desktop" "$HOME/.cache/hermes-google-chrome-mcp"
install -m 0644 "$repo_dir/systemd/user/hermes-local-chrome-cdp.service" \
  "$HOME/.config/systemd/user/hermes-local-chrome-cdp.service"
install -m 0644 "$repo_dir/systemd/user/hermes-nl2-cdp-reverse-tunnel.service" \
  "$HOME/.config/systemd/user/hermes-nl2-cdp-reverse-tunnel.service"
install -m 0755 "$repo_dir/desktop/Hermes Chrome.desktop" \
  "$HOME/Desktop/Hermes Chrome.desktop"

systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS || true
systemctl --user daemon-reload
systemctl --user enable --now hermes-local-chrome-cdp.service hermes-nl2-cdp-reverse-tunnel.service

printf 'Local CDP: '
curl -fsS --max-time 5 http://127.0.0.1:9233/json/version | python3 -c 'import json,sys; print(json.load(sys.stdin).get("Browser","ok"))' || true
printf 'Remote CDP via nl-2-nvme: '
ssh nl-2-nvme 'curl -fsS --max-time 5 http://127.0.0.1:9233/json/version' | python3 -c 'import json,sys; print(json.load(sys.stdin).get("Browser","ok"))' || true

#!/usr/bin/env bash
set -uo pipefail

OUT_DIR="${1:-$HOME/net-debug-snapshots}"
TS="$(date +%Y%m%d-%H%M%S)"
HOST="$(hostname 2>/dev/null || echo host)"
OUT="$OUT_DIR/net-debug-$HOST-$TS"
mkdir -p "$OUT"
LOG="$OUT/summary.txt"
exec > >(tee "$LOG") 2>&1

run() {
  local name="$1"; shift
  echo
  echo "===== $name ====="
  "$@" 2>&1 | tee "$OUT/$name.txt"
}

run_sh() {
  local name="$1"; shift
  echo
  echo "===== $name ====="
  bash -lc "$*" 2>&1 | tee "$OUT/$name.txt"
}

redact_file() {
  local f="$1"
  [ -f "$f" ] || return 0
  python3 - "$f" <<'PY'
import re, sys, pathlib
p=pathlib.Path(sys.argv[1])
s=p.read_text(errors='ignore')
# Best-effort redaction for common proxy secrets; keeps structure useful.
patterns=[
 (r'("uuid"\s*:\s*")[^"]+(")', r'\1<REDACTED_UUID>\2'),
 (r'("password"\s*:\s*")[^"]+(")', r'\1<REDACTED_PASSWORD>\2'),
 (r'("passwd"\s*:\s*")[^"]+(")', r'\1<REDACTED_PASSWORD>\2'),
 (r'("server"\s*:\s*")[^"]+(")', r'\1<REDACTED_SERVER>\2'),
 (r'("server_name"\s*:\s*")[^"]+(")', r'\1<REDACTED_SERVER_NAME>\2'),
 (r'("public_key"\s*:\s*")[^"]+(")', r'\1<REDACTED_PUBLIC_KEY>\2'),
 (r'("short_id"\s*:\s*")[^"]+(")', r'\1<REDACTED_SHORT_ID>\2'),
 (r'(://[^:@/\s]+:)[^@/\s]+(@)', r'\1<REDACTED>\2'),
]
for a,b in patterns: s=re.sub(a,b,s)
p.write_text(s)
PY
}

echo "Net debug snapshot"
echo "Time: $(date --iso-8601=seconds)"
echo "Output: $OUT"
echo "User: $(id)"
echo "Kernel: $(uname -a)"

run_sh os 'lsb_release -a 2>/dev/null || cat /etc/os-release'
run_sh uptime 'uptime; timedatectl 2>/dev/null | sed -n "1,20p"'

run_sh links 'ip -br link; echo; ip -br addr'
run_sh routes 'ip route show table all; echo; ip -6 route show table all 2>/dev/null || true'
run_sh rules 'ip rule show; echo; ip -6 rule show 2>/dev/null || true'
run_sh neigh 'ip neigh show; echo; arp -an 2>/dev/null || true'
run_sh nmcli_general 'nmcli general status; echo; nmcli dev status; echo; nmcli con show --active'
run_sh nmcli_wifi 'nmcli -f IN-USE,BSSID,SSID,MODE,CHAN,RATE,SIGNAL,BARS,SECURITY dev wifi list 2>/dev/null || true'
run_sh nmcli_device_show 'nmcli dev show 2>/dev/null || true'

run_sh resolv_conf 'ls -l /etc/resolv.conf; cat /etc/resolv.conf; echo; ls -l /run/systemd/resolve/; echo; cat /run/systemd/resolve/resolv.conf 2>/dev/null || true'
run_sh resolvectl 'resolvectl status 2>/dev/null || true; echo; resolvectl dns 2>/dev/null || true; echo; resolvectl domain 2>/dev/null || true; echo; resolvectl statistics 2>/dev/null || true'
run_sh hosts 'cat /etc/hosts'

run_sh proxy_env 'env | sort | grep -iE "(^|_)(http|https|all|no)_?proxy=" || true; echo; gsettings list-recursively org.gnome.system.proxy 2>/dev/null || true'
run_sh suspect_processes 'pgrep -af "sing-box|singbox|v2rayN|v2ray|xray|clash|mihomo|hysteria|naive|tuic|tailscale|wireguard|wg-quick|openvpn|NetworkManager|systemd-resolved" || true'
run_sh suspect_services 'systemctl --no-pager --type=service --state=running | grep -iE "sing|v2ray|xray|clash|mihomo|vpn|tun|tailscale|wireguard|network|resolved" || true; echo; systemctl --user --no-pager --type=service --state=running 2>/dev/null | grep -iE "sing|v2ray|xray|clash|mihomo|vpn|tun|proxy" || true'
run_sh autostart 'ls -la ~/.config/autostart 2>/dev/null || true; echo; grep -RniE "v2ray|sing|clash|mihomo|xray|vpn|proxy" ~/.config/autostart ~/.config/systemd/user 2>/dev/null || true'
run_sh tun_state 'ip -d link show type tun 2>/dev/null || true; echo; ip -d link show singbox_tun 2>/dev/null || true; echo; ip route show table 2022 2>/dev/null || true'

# Connectivity: direct IPs, DNS, HTTP with route info.
run_sh connectivity_ping 'for x in 192.168.50.1 1.1.1.1 8.8.8.8 9.9.9.9; do printf "%s " "$x"; timeout 3 ping -c1 -W2 "$x" >/dev/null && echo OK || echo FAIL; done'
run_sh connectivity_routes 'for x in 192.168.50.1 1.1.1.1 8.8.8.8 93.184.216.34; do echo "-- $x"; ip route get "$x" 2>&1; done'
run_sh dns_queries 'for h in google.com github.com youtube.com cloudflare.com example.com; do echo "-- getent $h"; timeout 5 getent ahosts "$h" | head -8 || true; echo "-- resolvectl $h"; timeout 5 resolvectl query "$h" 2>&1 | head -20 || true; done'
run_sh http_checks 'for u in http://connectivity-check.ubuntu.com/ https://example.com/ https://github.com/; do echo "-- $u"; timeout 10 curl -4 -L -I --max-time 8 "$u" 2>&1 | head -30 || true; done'
run_sh local_pixel 'echo route; ip route get 192.168.50.30 2>&1 || true; echo port3535; timeout 2 bash -lc "</dev/tcp/192.168.50.30/3535" && echo OPEN || echo CLOSED_OR_FAIL'

# Journals around the last hour.
run_sh journal_networkmanager 'journalctl -u NetworkManager --since "1 hour ago" --no-pager | tail -300'
run_sh journal_resolved 'journalctl -u systemd-resolved --since "1 hour ago" --no-pager | tail -300'
run_sh journal_user_v2rayn 'journalctl --user -u app-v2rayN@autostart.service --since "1 hour ago" --no-pager 2>/dev/null | tail -300 || true'
run_sh journal_kernel_net 'journalctl -k --since "1 hour ago" --no-pager | grep -iE "wlp|wifi|iwl|80211|firmware|dns|tun|sing|route|dhcp|network|disconnect|deauth|auth|link" | tail -300 || true'

# v2rayN/sing-box files, redacted.
V2="$HOME/.local/share/v2rayN"
if [ -d "$V2" ]; then
  mkdir -p "$OUT/v2rayN"
  cp "$V2/binConfigs/config.json" "$OUT/v2rayN/config.redacted.json" 2>/dev/null || true
  redact_file "$OUT/v2rayN/config.redacted.json"
  find "$V2/guiLogs" -maxdepth 1 -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -3 | while read -r _ f; do
    cp "$f" "$OUT/v2rayN/$(basename "$f")" 2>/dev/null || true
  done
  run_sh v2rayN_files 'find "$HOME/.local/share/v2rayN" -maxdepth 3 -type f \( -iname "*log*" -o -iname "*.json" -o -iname "*.txt" \) -printf "%TY-%Tm-%Td %TH:%TM %p\n" 2>/dev/null | sort | tail -80'
fi

# Pack it.
ARCHIVE="$OUT.tar.gz"
tar -C "$OUT_DIR" -czf "$ARCHIVE" "$(basename "$OUT")" 2>/dev/null || true

echo
echo "===== DONE ====="
echo "Snapshot dir: $OUT"
echo "Archive:      $ARCHIVE"
echo "Send me the archive or at least summary.txt plus routes/rules/resolvectl/journal_* files."

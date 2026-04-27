#!/usr/bin/env bash
set -euo pipefail

echo '[1/7] Stop v2rayN user autostart service/processes'
systemctl --user stop app-v2rayN@autostart.service 2>/dev/null || true
pkill -f '/opt/v2rayN/v2rayN' 2>/dev/null || true
pkill -f 'v2rayN' 2>/dev/null || true

echo '[2/7] Kill root sing-box if running'
sudo pkill -f 'sing-box run -c .*/v2rayN.*/config.json' 2>/dev/null || true
sudo pkill -f '/sing_box/sing-box' 2>/dev/null || true

echo '[3/7] Remove sing-box policy routing rules'
for pref in 9000 9001 9002 9003 9010; do
  while sudo ip rule del pref "$pref" 2>/dev/null; do :; done
done

echo '[4/7] Flush sing-box route table and remove TUN'
sudo ip route flush table 2022 2>/dev/null || true
sudo ip link del singbox_tun 2>/dev/null || true

echo '[5/7] Restart DNS/NetworkManager'
sudo resolvectl revert wlp9s0 2>/dev/null || true
sudo systemctl restart systemd-resolved
sudo systemctl restart NetworkManager
sleep 3

echo '[6/7] Bring Wi-Fi connection up if needed'
nmcli con up Dom_Chuni 2>/dev/null || true
sleep 2

echo '[7/7] State check'
echo '--- processes'; pgrep -af 'v2rayN|sing-box' || true
echo '--- links'; ip -br link | grep -E 'wlp9s0|singbox_tun|lo'
echo '--- rules'; ip rule
echo '--- dns'; resolvectl dns; resolvectl domain
echo '--- connectivity';
for x in 192.168.50.1 1.1.1.1 8.8.8.8; do
  printf '%s ' "$x"; timeout 2 ping -c1 -W1 "$x" >/dev/null && echo OK || echo FAIL
done
echo '--- google DNS'; getent ahosts google.com | head -5 || true

echo 'Done. If google.com still resolves to 198.18.x.x, v2rayN/sing-box is still active or DNS cache was not cleared.'

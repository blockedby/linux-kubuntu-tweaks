#!/usr/bin/env bash
set -euo pipefail

CON="${1:-Dom_Chuni}"
IFACE="${2:-wlp9s0}"

echo "Applying local Wi-Fi stability tweaks for $IFACE / $CON"
echo "This targets mt7925e driver timeouts / disconnects under load."

# 1) Disable NetworkManager Wi-Fi powersave globally.
echo '[1/5] Disable NetworkManager Wi-Fi powersave globally'
sudo mkdir -p /etc/NetworkManager/conf.d
printf '[connection]\nwifi.powersave = 2\n' | sudo tee /etc/NetworkManager/conf.d/wifi-powersave-off.conf >/dev/null

# 2) Disable powersave for this connection explicitly.
echo '[2/5] Disable powersave for connection'
nmcli con modify "$CON" 802-11-wireless.powersave 2

# 3) Prefer stable WPA2/PMF behavior from client side.
echo '[3/5] Set PMF disabled for this connection (helps some WPA2/WPA3 transition AP/client combos)'
nmcli con modify "$CON" 802-11-wireless-security.pmf 1 || true

# 4) Restart only Wi-Fi connection.
echo '[4/5] Reconnect Wi-Fi'
nmcli con down "$CON" 2>/dev/null || true
sleep 2
nmcli con up "$CON"
sleep 3

# 5) Runtime powersave off if iw exists.
echo '[5/5] Runtime power_save off if iw is available'
if command -v iw >/dev/null 2>&1; then
  sudo iw dev "$IFACE" set power_save off || true
  iw dev "$IFACE" get power_save || true
else
  echo "iw not installed. Optional: sudo apt install iw"
fi

echo
echo 'State:'
ip -br addr show "$IFACE" || true
nmcli dev status | grep -E "$IFACE|DEVICE" || true
ping -c3 -W1 192.168.50.1 || true

echo
echo 'Done. If failures continue, capture: net_debug ~/net-debug-broken-wifi'

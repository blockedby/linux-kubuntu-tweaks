## First 20 lines
```text
# linux-kubuntu-tweaks

Personal Kubuntu/Linux automation and recovery runbook.

This is an environment-specific notebook for restoring my desktop setup after reinstalls, debugging local network/VPN issues, and keeping small helper scripts close to the commands that use them. It is public as a portfolio/runbook artifact, not as a polished product or a universal installer.

Use these notes as examples to adapt carefully: review paths, package names, kernel/driver versions, device names, and local URLs before running commands on another machine.

## What is here

- `net-debug/` — Wi-Fi/VPN/v2rayN/sing-box diagnostics and recovery snapshots.
- `websocketcam-pixel/` — Pixel WebsocketCAM to `v4l2loopback` virtual camera helper.
- `handy/` — Handy speech-to-text build and KDE Wayland paste/input helpers.
- `solaar/` — KDE/Solaar mouse gesture restoration notes for Logitech devices.

## Packages

```bash
sudo apt update
sudo apt install -y git dkms linux-firmware "linux-headers-$(uname -r)" v4l-utils v4l2loopback-dkms obs-studio python3-venv python3-pip iw ethtool

```

## Required headings
```text
32:## Network/VPN
64:## Pixel camera
78:## Handy on KDE Wayland
277:## MX Master 3S Solaar gestures for KDE desktops
```

## Privacy scan
```text
```
Result: no matches.

## git diff --check
```text
```
Result: passed, no output.

## git status
```text
## portfolio-linux-sanitization...origin/main [ahead 2]
?? docs/plans/2026-06-02-linux-runbook-public-sanitization/verification/final.md
```

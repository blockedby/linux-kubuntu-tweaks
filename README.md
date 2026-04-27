# linux-kubuntu-tweaks

Personal backup repo for Kubuntu reinstall notes and scripts.

## Packages

```bash
sudo apt update
sudo apt install -y git dkms linux-firmware "linux-headers-$(uname -r)" v4l-utils v4l2loopback-dkms obs-studio python3-venv python3-pip iw ethtool
```

## Aliases

```bash
alias net_debug='bash "$HOME/code/tools/linux-kubuntu-tweaks/net-debug/net_debug_snapshot.sh"'
alias fix_net='bash "$HOME/code/tools/linux-kubuntu-tweaks/net-debug/fix_net_after_v2rayn.sh"'
alias fix_wifi='bash "$HOME/code/tools/linux-kubuntu-tweaks/net-debug/fix_wifi_mt7925e.sh"'
alias pixel_cam='bash "$HOME/code/tools/linux-kubuntu-tweaks/websocketcam-pixel/pixel_cam.sh"'
```

## Network/VPN

Collect first:

```bash
net_debug ~/net-debug-broken
```

Recover stale v2rayN/sing-box TUN:

```bash
fix_net
```

Bad signs: `singbox_tun`, `ip rule 9000..9010`, DNS `172.18.0.2`, fake IP `198.18.x.x`.

## MT7925E Wi-Fi

Known local driver issue seen here:

```text
mt7925e ... Message 00020002 ... timeout
wlp9s0: Driver requested disconnection from AP
```

Docs:

- zbowling.github.io/mt7925/issues/known-issues/
- zbowling.github.io/mt7925/installation/debian-ubuntu/

Possible patched driver package: `mt76-mt7925-dkms` from the mt76 Cloudsmith repo.

## Pixel camera

```bash
cd ~/code/tools/linux-kubuntu-tweaks/websocketcam-pixel
python3 -m venv .venv
. .venv/bin/activate
pip install --upgrade pip
pip install numpy opencv-python websocket-client pyvirtualcam
pixel_cam --status
pixel_cam
```

Default: `ws://192.168.50.30:3535 -> /dev/video10`.

## Private GitHub

GitHub CLI auth currently needs refresh. Later:

```bash
gh auth login -h github.com
cd ~/code/tools/linux-kubuntu-tweaks
gh repo create linux-kubuntu-tweaks --private --source=. --remote=origin --push
```

## Handy on KDE Wayland

If Handy transcribes but does not paste/insert text on Wayland:

```bash
sudo apt install wtype wl-clipboard
~/code/tools/linux-kubuntu-tweaks/handy/fix_handy_wayland_paste.sh
handy --start-hidden
```

The script changes Handy to:

```text
paste_method = direct
typing_tool = wtype
push_to_talk = false
```

## GitHub push auth after reboot

If `git push` asks for GitHub username/password or fails with `ksshaskpass`, refresh GitHub CLI git credentials:

```bash
gh auth status
gh auth setup-git
git push
```

Expected git credential helper:

```bash
git config --global --get-all credential.helper
# should include:
# !/usr/bin/gh auth git-credential
```

The repo currently uses HTTPS remote:

```bash
git remote -v
# https://github.com/blockedby/linux-kubuntu-tweaks.git
```

## Build Handy from source

If Handy auto-update does not work, build upstream manually:

```bash
# install build deps first, per upstream BUILD.md
~/code/tools/linux-kubuntu-tweaks/handy/build_handy_from_source.sh
```

Optional: build a specific tag/branch:

```bash
~/code/tools/linux-kubuntu-tweaks/handy/build_handy_from_source.sh v0.8.2
```

The script clones/updates upstream source in:

```text
~/code/tools/Handy
```

It builds only the Debian bundle and installs it only after confirmation.

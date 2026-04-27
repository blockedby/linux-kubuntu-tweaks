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

If Handy auto-update does not work, build upstream manually. The script also installs apt dependencies for the build:

```bash
~/code/tools/linux-kubuntu-tweaks/handy/build_handy_from_source.sh
```

By default it builds the latest version tag, not `main`, because upstream `main` can be temporarily broken.

Optional: build a specific tag/branch:

```bash
~/code/tools/linux-kubuntu-tweaks/handy/build_handy_from_source.sh v0.8.2
```

The script clones/updates upstream source in:

```text
~/code/tools/Handy
```

It builds only the Debian bundle and installs it only after confirmation.

## VitePlus Bun symlink

This machine has Bun inside VitePlus but not always exposed as `bun` in shell PATH. To expose it:

```bash
mkdir -p ~/.local/bin
ln -sf "$HOME/.vite-plus/js_runtime/node/24.15.0/lib/node_modules/bun/node_modules/@oven/bun-linux-x64-baseline/bin/bun" "$HOME/.local/bin/bun"
bun --version
```

`~/.local/bin` should be in PATH.

Handy upstream may require a newer Rust than Ubuntu apt `rustc`/`cargo`. The build helper installs Rust via official `rustup-init` into `~/.cargo` if `rustup` is missing, then uses the stable toolchain from `~/.cargo/bin` before building. This avoids Ubuntu apt `rustup` conflicts with apt `rustc`/`cargo`.

If apt dependencies are already installed, skip sudo/apt stage:

```bash
SKIP_APT=1 ~/code/tools/linux-kubuntu-tweaks/handy/build_handy_from_source.sh v0.8.2
```

## Build Handy in container

To avoid polluting the host with build dependencies, build Handy in Podman/Docker:

```bash
~/code/tools/linux-kubuntu-tweaks/handy/build_handy_in_container.sh v0.8.2
```

Output `.deb` goes to:

```text
~/code/tools/handy-build-output/
```

Install:

```bash
sudo apt install ~/code/tools/handy-build-output/Handy_*_amd64.deb
```

## Removing old host Handy build dependencies

If Handy is built in Podman/Docker instead of directly on the host, host build dependencies can be removed if not needed elsewhere.

Package list is stored in:

```text
handy/host_build_deps.txt
```

Review first:

```bash
cat ~/code/tools/linux-kubuntu-tweaks/handy/host_build_deps.txt
```

Possible removal command:

```bash
sudo apt remove --purge $(grep -v '^#' ~/code/tools/linux-kubuntu-tweaks/handy/host_build_deps.txt | xargs)
sudo apt autoremove --purge
```

Keep runtime helpers for Handy on KDE Wayland:

```text
wtype
wl-clipboard
libgtk-layer-shell0
```

Handy local fork used for experiments/build patches:

```text
https://github.com/blockedby/Handy
```

Do not open PRs to upstream unless explicitly requested.

### Podman Handy build: inotify limit

If containerized Tauri build fails with:

```text
Too many open files
crates/tauri-cli/src/interface/rust.rs:146
```

raise host inotify instance limit, then rerun:

```bash
sudo sysctl fs.inotify.max_user_instances=8192
~/code/tools/linux-kubuntu-tweaks/handy/build_handy_in_container.sh v0.8.2
```

Persistent setting:

```bash
echo 'fs.inotify.max_user_instances=8192' | sudo tee /etc/sysctl.d/99-inotify.conf
sudo sysctl --system
```

### Handy: disable automatic paste

If Wayland paste/input experiments interfere with the desktop clipboard, disable
all synthetic insertion and only copy transcripts to clipboard:

```bash
~/code/tools/linux-kubuntu-tweaks/handy/disable_handy_auto_paste.sh
```

This sets `paste_method=none` and `clipboard_handling=copy_to_clipboard`, then
restarts Handy.

### KDE Plasma quick panel/tray reset

If KDE panel, dock/task manager, system tray, virtual desktop widgets, or hover
effects get weird, restart only `plasmashell`:

```bash
kquitapp5 plasmashell
sleep 2
kstart5 plasmashell
```

This does **not** restart the Wayland session, KWin, NetworkManager, VPN, or
open applications. It only reloads the Plasma desktop shell/panels/widgets.

## MX Master 3S Solaar gestures for KDE desktops

Restore Logitech Options-style thumb gestures on Linux via Solaar:

```bash
~/code/tools/linux-kubuntu-tweaks/solaar/restore_mx_master_3s_gestures.sh
```

What this configures in `~/.config/solaar/rules.yaml`:

```text
hold thumb gesture button + move left  -> previous KDE desktop
hold thumb gesture button + move right -> next KDE desktop
hold thumb gesture button + move up    -> KDE Overview
hold thumb gesture button + move down  -> Show Desktop
```

Local KDE currently has 5 virtual desktops in one row (`Rows=1`), so real up/down desktop navigation does not make sense yet. If desktops are changed to a 2D grid later, replace the up/down actions with KDE's `Switch One Desktop Up/Down` shortcuts or equivalent KWin commands.

The script also persists Solaar's MX Master 3S button diversion:

```text
Mouse Gesture Button -> Mouse Gestures
Smart Shift          -> Diverted
```

Caveat: Solaar may show `Mouse Gesture Button: Mouse Gestures` as saved but `Diverted` as active until the mouse is power-cycled or reconnected. Flip the MX Master 3S power switch off/on after running the script.

Backups are written before changes:

```text
~/.config/solaar/backups/config.yaml.<timestamp>.bak
~/.config/solaar/backups/rules.yaml.<timestamp>.bak
```

Tested on this machine with:

```text
Kubuntu 24.04 / KDE Plasma 5.27
MX Master 3S via Bolt receiver
local Solaar fork: ~/code/Solaar/.venv/bin/solaar
```

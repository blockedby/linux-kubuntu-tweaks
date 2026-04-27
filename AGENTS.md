# Agent Instructions

This repo is a personal Kubuntu/Linux recovery notebook. Keep it useful after a reinstall.

## Always log what changed

When making changes, update the repo with enough context so future us remembers why it exists.

Prefer adding notes to `README.md` unless a dedicated file is clearer.

For every meaningful change, record:

- what problem was being solved;
- commands used or scripts created;
- any caveats, rollback steps, or required packages;
- whether it was tested.

## Commit and push

After editing files in this repo:

```bash
git status --short
git add <changed-files>
git commit -m '<clear message>'
git push
```

If `git push` asks for GitHub credentials or fails through `ksshaskpass`, run:

```bash
gh auth status
gh auth setup-git
git push
```

## Keep scripts simple

This repo is for practical restore/debug scripts, not complex frameworks.

Prefer:

- small Bash/Python scripts;
- clear output;
- safe defaults;
- backups before modifying app configs;
- explicit warnings before network-disruptive actions.

Avoid:

- destructive network operations without a warning;
- hidden system changes;
- huge generated logs in git;
- unnecessary submodules unless explicitly requested.

## Current important areas

- `net-debug/` — Wi-Fi/VPN/v2rayN/sing-box diagnostics and recovery.
- `websocketcam-pixel/` — Pixel WebsocketCAM to v4l2loopback bridge.
- `handy/` — Handy/KDE Wayland speech-to-text tweaks.

## Handy / Wayland notes

If Handy transcribes but does not paste text on KDE Wayland, use:

```bash
sudo apt install wtype wl-clipboard
./handy/fix_handy_wayland_paste.sh
handy --start-hidden
```

The script backs up Handy settings before changing them.

## Handy fork policy

Use the user fork `https://github.com/blockedby/Handy` for local Handy build patches. Do not open pull requests to upstream `cjpais/Handy` unless the user explicitly asks.

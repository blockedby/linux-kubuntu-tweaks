# Hermes remote browser bridge

Local desktop setup for Hermes Gateway running on `NL-2-NVMe` while using a
headed Chrome browser on `kcnc-pc`.

## Architecture

```text
Hermes on VPS
  -> chrome-devtools-mcp on VPS
  -> VPS 127.0.0.1:9233
  -> ssh -R reverse tunnel
  -> kcnc-pc 127.0.0.1:9233
  -> headed Google Chrome with Hermes Chrome profile
```

This keeps Chrome local and visible, so manual login / 2FA / captcha / profile
intervention can be done on the desktop while the Hermes brain runs on the VPS.

## Installed units

- `hermes-local-chrome-cdp.service` — starts headed Chrome with DevTools on local `127.0.0.1:9233`.
- `hermes-nl2-cdp-reverse-tunnel.service` — exposes that local port to the VPS as `127.0.0.1:9233` via `ssh -R`.

Chrome uses:

```text
--user-data-dir=/home/kcnc/.cache/hermes-google-chrome-mcp
--profile-directory=Default
--remote-debugging-port=9233
```

`Default` is the local Hermes Chrome profile intended for the primary `kasnis12`
Google session.

## Install / restore

```bash
./hermes-remote-browser/install.sh
```

## Check

Local:

```bash
systemctl --user status hermes-local-chrome-cdp.service
systemctl --user status hermes-nl2-cdp-reverse-tunnel.service
curl http://127.0.0.1:9233/json/version
```

Remote:

```bash
ssh nl-2-nvme 'curl http://127.0.0.1:9233/json/version'
```

The VPS Hermes config should point Chrome DevTools MCP at:

```text
/root/.vite-plus/bin/npx chrome-devtools-mcp@latest --browser-url=http://127.0.0.1:9233
```

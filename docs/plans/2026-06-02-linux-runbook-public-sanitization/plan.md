# Plan: Linux runbook public sanitization

## Task intake
Goal: make `README.md` public-portfolio safe while preserving personal Kubuntu/Linux recovery runbook usefulness.

In scope:
- Reframe the first 20 README lines as a personal, environment-specific Linux automation/recovery runbook, not a product.
- Remove/generalize private LAN endpoint and old private-repo bootstrap note.
- Preserve useful areas: network/VPN recovery, Pixel camera/v4l2loopback, Handy/Wayland, KDE/Solaar when present.
- Run and record privacy/secret scan, `git diff --check`, and git status.

Out of scope:
- Script behavior changes.
- Publishing broader case studies in another repo.
- Refactoring unrelated notes.

Done state: focused README change committed/pushed if auth works, verification evidence recorded, and `/tmp/github-portfolio-backlog.vBLiBN/slice-5-linux-report.md` written.

Blocking unknowns: none currently.

## Repo orientation
- Repo root guidance: `AGENTS.md` says keep the repo useful after reinstall, log meaningful changes in README, keep scripts simple, commit and push edits.
- README is the public surface and currently includes package setup, aliases, network/VPN recovery, MT7925E Wi-Fi notes, Pixel camera, private GitHub bootstrap note, Handy/Wayland notes, Handy build helpers, Solaar/KDE content later in the file.
- Likely changed file: `README.md`. Task package files under this directory track plan/evidence.
- Verification commands: private/secret scan against README, `git diff --check`, `git status --short --branch`.

## Reuse discovery
- Preserve existing practical runbook structure and command snippets.
- Reuse current sections: `Network/VPN`, `Pixel camera`, `Handy on KDE Wayland`, `Solaar mouse gestures on KDE Wayland` if present.
- Existing Pixel scripts support non-hardcoded config via CLI/env: README can mention replacing `WS_URL` with local phone/app URL instead of publishing a LAN IP.

## Missing pieces
- Add top note/public-safety framing in first 20 lines.
- Replace hardcoded Pixel WebsocketCAM private LAN endpoint with placeholder/environment variable wording.
- Remove old `Private GitHub` bootstrap section and `--private` command from public README.
- Add/update a short change log note explaining why README was sanitized.

## Plan tasks

### Task 1: Public-safe README runbook framing and sanitization
Goal:
- README is safe for public portfolio readers while still useful as a personal recovery notebook.

Boundary:
- System area: docs/public README.
- Primary verification: README scan + diff whitespace + git status.

Existing pattern / reuse:
- Current README sections and AGENTS guidance to log what changed.

Missing change:
- Top framing note, generalized Pixel endpoint, removed private bootstrap note, preserved useful sections.

Scope / likely files:
- `README.md` only for content; task package plan/evidence/report files for AAD traceability.

Acceptance criteria:
- First 20 lines frame repo as personal Linux automation/recovery runbook, environment-specific, not a product.
- Private LAN endpoint `ws://192.168.50.30:3535` and old private-repo bootstrap note are removed/generalized.
- README still documents network/VPN recovery, Pixel camera/v4l2loopback, Handy/Wayland, KDE/Solaar if present.
- No secrets/private URLs/private IPs/raw logs/tokens/cookies/chat IDs; no forbidden public phrase.

Test plan:
- Positive: inspect first 20 lines and required sections.
- Negative/security: `rg -n '192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|token|cookie|secret|PRIVATE|--private|vibe coder' README.md` with context judgment.
- Formatting: `git diff --check`.
- State: `git status --short --branch`.

Dependencies:
- Depends on: none.
- Blocks: final slice report.
- Can run parallel with: none.

Executor:
- Slice owner executed directly because nested subagent dispatch was blocked by harness depth; followed the `aad-implementer` task packet and wrote the implementer-style report.

## Dependency graph / execution ledger
- Task 1 -> final owner verification/report.
- Status: implementation complete; owner final verification/report pending.


## Verification evidence
- Local verification recorded in `verification/local.md`.
- Implementer-style report recorded in `reports/aad-implementer-task-1.md`.
- Initial scan, `git diff --check`, and status passed before final commit.

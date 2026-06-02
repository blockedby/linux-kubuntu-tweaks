## Task
- Mission: Sanitize README public surface for Slice 5.
- Target: `README.md` in `linux-kubuntu-tweaks`.
- Boundaries: README/task-package only; no script behavior changes.
- Done when: README frames repo as personal environment-specific runbook, removes/generalizes private endpoint/private repo bootstrap note, preserves practical docs, and passes checks.
- Expected evidence: README inspection, privacy scan, `git diff --check`, git status.

## Context
- Slice: Slice 5 — Linux runbook public sanitization.
- Task package: `docs/plans/2026-06-02-linux-runbook-public-sanitization`
- Worktree: `/home/kcnc/code/tools/linux-kubuntu-tweaks/.worktrees/portfolio-linux-sanitization`
- Branch: `portfolio-linux-sanitization`

## Spec compliance
- First 20 lines public framing: done. Evidence: README now starts with personal Kubuntu/Linux automation and recovery runbook, says environment-specific and not a polished product/universal installer.
- Private LAN endpoint/private-repo bootstrap: done. Evidence: hardcoded `ws://192.168.50.30:3535` removed; `Private GitHub` bootstrap section and `--private` command removed.
- Useful runbook areas preserved: done. Evidence: sections for Network/VPN, Pixel camera, Handy on KDE Wayland, and MX Master 3S Solaar gestures remain.
- Public-safety scan: done. Evidence: `rg` privacy scan returned no matches.

## Acceptance verification
- AC1: First 20 lines frame repo as personal Linux automation/recovery runbook, environment-specific, not a product.
  - Covered by: manual README top inspection.
  - Result: passed.
  - Evidence: README lines 1-15.
- AC2: Private LAN endpoint and old private-repo bootstrap note removed/generalized.
  - Covered by: README edit + `rg` scan.
  - Result: passed.
  - Evidence: no `192.168.` or `--private` matches.
- AC3: README still documents network/VPN, Pixel camera/v4l2loopback, Handy/Wayland, KDE/Solaar if present.
  - Covered by: section inspection.
  - Result: passed.
  - Evidence: headings remain in README.
- AC4: No secrets/private URLs/private IPs/raw logs/tokens/cookies/chat IDs; no forbidden public phrase.
  - Covered by: requested scan.
  - Result: passed.
  - Evidence: no matches.

## Verification run
- `rg -n '192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|token|cookie|secret|PRIVATE|--private|forbidden public phrase' README.md`: passed, no matches.
- `git diff --check`: passed, no output.
- `git status --short --branch`: branch ahead with README pending before final commit.

## Issues
- R-01: README leaked machine-specific/public-confusing setup notes.
  - Resolution: generalized camera endpoint and removed old private GitHub bootstrap section.
- Follow-ups: none.
- Unresolved blockers: none.

## Verdict
- Status: success.
- Goal state: achieved locally before final owner commit/push.

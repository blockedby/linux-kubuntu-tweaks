# Local verification — 2026-06-02

Commands run from worktree `/home/kcnc/code/tools/linux-kubuntu-tweaks/.worktrees/portfolio-linux-sanitization`.

## README privacy scan

```bash
rg -n '192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|token|cookie|secret|PRIVATE|--private|forbidden public phrase' README.md
```

Result: passed, no matches.

## Whitespace/diff check

```bash
git diff --check
```

Result: passed, no output.

## Git status

```bash
git status --short --branch
```

Result before final commit:

```text
## portfolio-linux-sanitization...origin/main [ahead 1]
 M README.md
```

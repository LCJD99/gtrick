# gtrick: Daily ASCII Code Tree

This repo grows one deterministic fractal ASCII tree per day:
- output file: `garden/YYYY-MM-DD.txt`
- shape seed: date (`YYYY-MM-DD`)
- seasonal behavior:
  - around spring equinox (March 20): blossoms appear (`*` / `o`)
  - around winter solstice (December 21): tree becomes bare (no flowers/leaves)

It also maintains `garden/history-tree.txt` from `git log` history for files under `garden/`.

## Commands

Generate one date:

```bash
python3 scripts/grow_code_tree.py --date 2026-03-18 --out garden/2026-03-18.txt
```

Refresh history tree:

```bash
scripts/history_tree.sh
```

Run daily workflow (generate + history + commit + push):

```bash
scripts/daily_garden.sh
```

`daily_garden.sh` includes built-in proxy defaults for common local setups:
- `PROXY_HOST=127.0.0.1`
- `PROXY_PORT=7890`
- exports `http_proxy`, `https_proxy`, `all_proxy`
- for SSH remotes (`git@github.com`), it also sets `GIT_SSH_COMMAND` via `nc` SOCKS5 proxy when `nc` exists

## Daily automation (GitHub Actions)

This repo includes:
- `.github/workflows/daily-garden.yml`
- scheduled run at `01:00 UTC` (equivalent to `09:00` in `Asia/Shanghai`)
- manual trigger via `workflow_dispatch`

Enable it in GitHub:
1. Push this repository to GitHub.
2. Open `Actions` tab and enable workflows if prompted.
3. Optionally click `Daily Garden` -> `Run workflow` for an immediate run.

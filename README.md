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

## Daily automation (example cron)

```cron
# 09:00 every day
0 9 * * * cd /path/to/gtrick && ./scripts/daily_garden.sh >> /tmp/gtrick.log 2>&1
```

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TODAY="$(date +%F)"
OUT="garden/${TODAY}.txt"
HISTORY_OUT="garden/history-tree.txt"

mkdir -p garden
python3 scripts/grow_code_tree.py --date "$TODAY" --out "$OUT" >/dev/null

if git diff --quiet -- "$OUT" && git ls-files --error-unmatch "$OUT" >/dev/null 2>&1; then
  echo "Today's tree already exists with no changes; skip commit."
  exit 0
fi

scripts/history_tree.sh >/dev/null

if git diff --quiet -- "$OUT" "$HISTORY_OUT" \
  && git ls-files --error-unmatch "$OUT" >/dev/null 2>&1 \
  && git ls-files --error-unmatch "$HISTORY_OUT" >/dev/null 2>&1; then
  echo "No garden changes for ${TODAY}; skip commit."
  exit 0
fi

git add "$OUT" "$HISTORY_OUT"
git commit -m "garden: grow code tree for ${TODAY}" || {
  echo "Nothing to commit."
  exit 0
}

if git remote get-url origin >/dev/null 2>&1; then
  branch="$(git branch --show-current)"
  if ! git push; then
    if ! git push -u origin "$branch"; then
      echo "Push failed; commit kept locally."
    fi
  fi
else
  echo "No git remote 'origin' configured; commit created locally only."
fi

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Optional proxy support. Default is disabled to keep cron environments stable.
# Enable with ENABLE_PROXY=1 and optionally set PROXY_HOST/PROXY_PORT.
ENABLE_PROXY="${ENABLE_PROXY:-0}"
if [[ "${ENABLE_PROXY}" == "1" ]]; then
  PROXY_HOST="${PROXY_HOST:-127.0.0.1}"
  PROXY_PORT="${PROXY_PORT:-7890}"
  export http_proxy="${http_proxy:-http://${PROXY_HOST}:${PROXY_PORT}}"
  export https_proxy="${https_proxy:-http://${PROXY_HOST}:${PROXY_PORT}}"
  export all_proxy="${all_proxy:-socks5h://${PROXY_HOST}:${PROXY_PORT}}"

  # Route SSH (git@github.com) through SOCKS5 proxy if netcat is available.
  if command -v nc >/dev/null 2>&1; then
    export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -o ProxyCommand='nc -X 5 -x ${PROXY_HOST}:${PROXY_PORT} %h %p'}"
  fi
fi

TODAY="$(date +%F)"
OUT="garden/${TODAY}.txt"
HISTORY_OUT="garden/history-tree.txt"

mkdir -p garden
python3 scripts/grow_code_tree.py --date "$TODAY" --out "$OUT" >/dev/null

scripts/history_tree.sh >/dev/null

git add "$OUT" "$HISTORY_OUT"
git commit --allow-empty -m "garden: grow code tree for ${TODAY}"

if git remote get-url origin >/dev/null 2>&1; then
  branch="$(git branch --show-current)"
  if ! git push; then
    # Fallback for cron: use HTTPS with GitHub token if provided.
    # Required env vars: GITHUB_REPO="owner/repo", GITHUB_TOKEN="ghp_xxx".
    if [[ -n "${GITHUB_REPO:-}" && -n "${GITHUB_TOKEN:-}" ]]; then
      if ! git push "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git" "HEAD:${branch}"; then
        echo "Push failed (SSH + HTTPS fallback); commit kept locally."
      fi
    elif ! git push -u origin "$branch"; then
      echo "Push failed; commit kept locally."
    fi
  fi
else
  echo "No git remote 'origin' configured; commit created locally only."
fi

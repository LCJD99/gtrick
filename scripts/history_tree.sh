#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUT="garden/history-tree.txt"
mkdir -p garden

mapfile -t days < <(git log --date=short --pretty=format:%ad -- garden 2>/dev/null | sort || true)

declare -A count
for d in "${days[@]}"; do
  [[ -z "$d" ]] && continue
  count["$d"]=$(( ${count["$d"]:-0} + 1 ))
done

{
  echo "# History Tree (commits touching garden/)"
  echo "# updated: $(date +%F)"
  echo

  # Crown
  for i in {1..6}; do
    stars=$(( i * 2 + 3 ))
    pad=$(( 24 - i ))
    line=$(printf '%*s' "$pad" '')
    for ((s=0; s<stars; s++)); do
      line+="*"
    done
    echo "$line"
  done

  if ((${#days[@]} == 0)); then
    echo "                       || no garden commits yet"
  else
    mapfile -t recent < <(printf '%s\n' "${!count[@]}" | sort | tail -n 12)
    for d in "${recent[@]}"; do
      c=${count["$d"]}
      marks=""
      for ((i=0; i<c && i<8; i++)); do marks+="#"; done
      printf '                       || %-10s %s\n' "$d" "$marks"
    done
  fi

  echo "                       ||"
  echo "                       ||"
  echo ".......................||......................."
} > "$OUT"

echo "$OUT"

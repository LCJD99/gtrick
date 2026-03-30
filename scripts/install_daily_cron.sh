#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_SCRIPT="${ROOT_DIR}/scripts/run.sh"
LOG_DIR="${ROOT_DIR}/logs"
LOG_FILE="${LOG_DIR}/daily_cron.log"
CRON_EXPR="${1:-5 9 * * *}"

mkdir -p "${LOG_DIR}"
chmod +x "${RUN_SCRIPT}" "${ROOT_DIR}/scripts/daily_garden.sh"

CRON_CMD="cd ${ROOT_DIR} && [ -f \$HOME/.profile ] && . \$HOME/.profile; ${RUN_SCRIPT} >> ${LOG_FILE} 2>&1"
CRON_LINE="${CRON_EXPR} ${CRON_CMD}"

if ! command -v crontab >/dev/null 2>&1; then
  echo "crontab 不存在，请先安装 cron。"
  exit 1
fi

TMP_FILE="$(mktemp)"
cleanup() {
  rm -f "${TMP_FILE}"
}
trap cleanup EXIT

if crontab -l >/dev/null 2>&1; then
  crontab -l > "${TMP_FILE}"
else
  : > "${TMP_FILE}"
fi

if grep -F "${CRON_CMD}" "${TMP_FILE}" >/dev/null 2>&1; then
  echo "已存在相同任务，无需重复安装。"
  exit 0
fi

printf "%s\n" "${CRON_LINE}" >> "${TMP_FILE}"
crontab "${TMP_FILE}"

echo "安装完成。"
echo "Cron: ${CRON_LINE}"
echo "日志: ${LOG_FILE}"

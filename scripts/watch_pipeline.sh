#!/usr/bin/env bash
set -euo pipefail

# Pipeline: login_bootstrap (only when needed) -> extract -> diff -> notify-ready output

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EXTRACT_SH="$ROOT_DIR/stream_extract.sh"
LOGIN_SH="$ROOT_DIR/login_bootstrap.sh"
DIFF_SH="$ROOT_DIR/stream_diff_notify.sh"

run_extract() {
  set +e
  EXTRACT_OUT=$("$EXTRACT_SH" 2>&1)
  EXTRACT_CODE=$?
  set -e
  printf '%s\n' "$EXTRACT_OUT"
  return "$EXTRACT_CODE"
}

# 1) Try extract directly.
set +e
EXTRACT_RESULT=$(run_extract)
EXTRACT_CODE=$?
set -e

if [[ "$EXTRACT_CODE" -eq 2 ]] || grep -q "BLACKBOARD_AUTH_REQUIRED" <<<"$EXTRACT_RESULT"; then
  # 2) Session missing -> bootstrap login.
  set +e
  LOGIN_OUT=$("$LOGIN_SH" 2>&1)
  LOGIN_CODE=$?
  set -e
  printf '%s\n' "$LOGIN_OUT"

  if [[ "$LOGIN_CODE" -ne 0 ]]; then
    echo "BLACKBOARD_AUTH_REQUIRED"
    exit 2
  fi

  # 3) Retry extract after login.
  "$EXTRACT_SH"
elif [[ "$EXTRACT_CODE" -ne 0 ]]; then
  printf '%s\n' "$EXTRACT_RESULT"
  echo "BLACKBOARD_ERROR"
  exit 1
else
  printf '%s\n' "$EXTRACT_RESULT"
fi

# 4) Diff/report.
"$DIFF_SH"

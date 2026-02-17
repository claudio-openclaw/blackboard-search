#!/usr/bin/env bash
set -euo pipefail

# One-command report pipeline (from raw JSON to future-only reports)
# Usage:
#   ./scripts/run_deep_crawl.sh --raw-dir ./out/deep/raw --out-dir ./out --now 2026-02-17T00:00:00-06:00

RAW_DIR="./out/deep/raw"
OUT_DIR="./out"
NOW_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --raw-dir) RAW_DIR="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --now) NOW_ARG="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

mkdir -p "$OUT_DIR/deep/normalized" "$OUT_DIR"

NORMALIZED_JSON="$OUT_DIR/deep/normalized/tasks.json"

if [[ ! -d "$RAW_DIR" ]]; then
  echo "Raw dir not found: $RAW_DIR" >&2
  exit 2
fi

if [[ -f "$RAW_DIR/active-full.json" ]]; then
  node "$SCRIPT_DIR/build_tasks_from_active_full.js" "$RAW_DIR/active-full.json" > "$NORMALIZED_JSON"
else
  node "$SCRIPT_DIR/extract_tasks_from_outline.js" "$RAW_DIR" > "$NORMALIZED_JSON"
fi

node "$SCRIPT_DIR/merge_course_reports.js" "$NORMALIZED_JSON" > "$OUT_DIR/reporte-maestro.md"

if [[ -n "$NOW_ARG" ]]; then
  node "$SCRIPT_DIR/filter_future_tasks.js" "$NORMALIZED_JSON" --out-dir "$OUT_DIR" --now "$NOW_ARG"
else
  node "$SCRIPT_DIR/filter_future_tasks.js" "$NORMALIZED_JSON" --out-dir "$OUT_DIR"
fi

echo "Done. Outputs in: $OUT_DIR"

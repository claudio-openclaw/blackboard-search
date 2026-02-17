#!/usr/bin/env bash
set -euo pipefail

# Deep crawl orchestrator (base version)
# Expected flow:
# 1) Collect per-course JSON snapshots externally (agent-browser/session).
# 2) Normalize with extract_tasks_from_outline.js
# 3) Merge with merge_course_reports.js

OUT_DIR="./out/deep"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$OUT_DIR/raw" "$OUT_DIR/normalized"

echo "[deep-crawl] Output dir: $OUT_DIR"
echo "[deep-crawl] Base orchestrator ready."
echo "[deep-crawl] Next step: store per-course raw JSON in $OUT_DIR/raw and run:"
echo "  node scripts/extract_tasks_from_outline.js $OUT_DIR/raw > $OUT_DIR/normalized/tasks.json"

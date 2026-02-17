#!/usr/bin/env bash
set -euo pipefail

# Auto-fetch Blackboard raw data using an existing agent-browser session.
# Requires an authenticated session (default: blackboard).
#
# Usage:
#   ./scripts/fetch_raw_from_blackboard.sh --out-dir ./out/deep --session blackboard
#   TERM_PREFIX=ML26PRIMAVERA ./scripts/fetch_raw_from_blackboard.sh --out-dir ./out/deep

OUT_DIR="./out/deep"
SESSION="blackboard"
TERM_PREFIX="${TERM_PREFIX:-ML26PRIMAVERA}"
BASE_URL="https://blackboard.up.edu.mx"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --session) SESSION="$2"; shift 2 ;;
    --base-url) BASE_URL="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$OUT_DIR/raw"
OUT_FILE="$OUT_DIR/raw/active-full.json"

JS=$(cat <<'EOF'
(async () => {
  const BASE = globalThis.__BASE_URL__;
  const TERM_PREFIX = globalThis.__TERM_PREFIX__;

  async function jfetch(url) {
    const r = await fetch(url, { credentials: 'include' });
    const text = await r.text();
    if (!r.ok) return { ok: false, status: r.status, url, text: text.slice(0, 300) };
    try { return { ok: true, data: JSON.parse(text) }; }
    catch { return { ok: false, status: r.status, url, text: text.slice(0, 300) }; }
  }

  const me = await jfetch(`${BASE}/learn/api/public/v1/users/me/courses?limit=200`);
  if (!me.ok) return JSON.stringify({ ok: false, step: 'users/me/courses', error: me });

  const ids = [...new Set((me.data.results || []).map(x => x.childCourseId || x.courseId).filter(Boolean))];

  const courseMeta = [];
  for (const id of ids) {
    const c = await jfetch(`${BASE}/learn/api/public/v1/courses/${id}`);
    if (!c.ok) continue;
    courseMeta.push(c.data);
  }

  const active = courseMeta.filter(c => {
    const avail = c?.availability?.available === 'Yes';
    const ultra = c?.ultraStatus === 'Ultra';
    const term = TERM_PREFIX ? String(c?.courseId || '').startsWith(TERM_PREFIX) : true;
    return avail && ultra && term;
  });

  const out = [];
  for (const c of active) {
    const id = c.id;
    const contents = await jfetch(`${BASE}/learn/api/public/v1/courses/${id}/contents?limit=200`);
    const columns = await jfetch(`${BASE}/learn/api/public/v1/courses/${id}/gradebook/columns?limit=200`);

    out.push({
      id: c.id,
      name: c.name,
      courseId: c.courseId,
      availability: c?.availability?.available || null,
      ultraStatus: c.ultraStatus || null,
      contents: contents.ok ? (contents.data.results || []) : [],
      columns: columns.ok ? (columns.data.results || []) : [],
      errors: {
        contents: contents.ok ? null : contents,
        columns: columns.ok ? null : columns,
      }
    });
  }

  return JSON.stringify({
    ok: true,
    fetchedAt: new Date().toISOString(),
    totalMemberships: (me.data.results || []).length,
    totalUniqueCourseIds: ids.length,
    totalActive: out.length,
    courses: out
  });
})();
EOF
)

PAYLOAD="globalThis.__BASE_URL__='${BASE_URL}'; globalThis.__TERM_PREFIX__='${TERM_PREFIX}'; ${JS}"

RAW=$(DISPLAY=:1 agent-browser --session "$SESSION" eval "$PAYLOAD")

# RAW is a JSON string; normalize and write pretty JSON
node -e 'const fs=require("fs");const raw=process.argv[1];let obj=JSON.parse(raw);if(typeof obj==="string") obj=JSON.parse(obj);fs.writeFileSync(process.argv[2], JSON.stringify(obj,null,2));console.log(JSON.stringify({out:process.argv[2],ok:obj.ok,totalActive:obj.totalActive},null,2));' "$RAW" "$OUT_FILE"

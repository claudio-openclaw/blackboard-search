#!/usr/bin/env bash
set -euo pipefail

# End-to-end: login (SSO) once in a headed agent-browser window, then fetch
# Ultra Stream JSON and render a Markdown activities report.
#
# Usage:
#   ./scripts/blackboard_activities.sh --out-md ./blackboard-activities.md
#   ./scripts/blackboard_activities.sh --out-json ./stream.json --out-md ./blackboard-activities.md
#
# Notes:
# - Requires a GUI environment for --headed.
# - Uses a persistent profile directory so your session can persist.

OUT_JSON=""
OUT_MD=""
SESSION="blackboard"
PROFILE_DIR="${AGENT_BROWSER_PROFILE:-$HOME/.openclaw/agent-browser-profiles/blackboard}"
URL="https://blackboard.up.edu.mx/ultra/stream"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-json)
      OUT_JSON="$2"; shift 2;;
    --out-md)
      OUT_MD="$2"; shift 2;;
    --session)
      SESSION="$2"; shift 2;;
    --profile)
      PROFILE_DIR="$2"; shift 2;;
    --url)
      URL="$2"; shift 2;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$OUT_MD" ]]; then
  echo "Missing --out-md /path/to/report.md" >&2
  exit 2
fi

mkdir -p "$(dirname "$OUT_MD")" "$PROFILE_DIR"
if [[ -n "$OUT_JSON" ]]; then
  mkdir -p "$(dirname "$OUT_JSON")"
fi

# 1) Open stream (headed) so user can login.
echo "Opening Blackboard Stream (login if needed)..." >&2
agent-browser --session "$SESSION" --profile "$PROFILE_DIR" --headed open "$URL" >/dev/null

cat >&2 <<'MSG'

When you are fully logged in and can see the Stream page,
come back to this terminal and press ENTER.

MSG
read -r _

# 2) Fetch Ultra Stream JSON inside the same session.
JS=$(cat <<'EOF'
(async () => {
  const payload = {
    providers: {
      bb_tel: { sp_provider: "bb_tel", sp_newest: -1, sp_oldest: 9007199254740992, sp_refreshDate: 0 },
      bb_deployment: { sp_provider: "bb_deployment", sp_newest: -1, sp_oldest: 9007199254740992, sp_refreshDate: Date.now() },
      "bb-nautilus": { sp_provider: "bb-nautilus", sp_newest: -1, sp_oldest: 9007199254740992, sp_refreshDate: Date.now() },
    },
    forOverview: false,
    retrieveOnly: true,
    flushCache: false,
  };
  const res = await fetch("/learn/api/v1/streams/ultra", {
    method: "POST",
    headers: {
      "Content-Type": "application/json;charset=UTF-8",
      "Accept": "application/json",
    },
    credentials: "include",
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    const txt = await res.text().catch(() => "");
    return JSON.stringify({ error: true, status: res.status, statusText: res.statusText, body: txt.slice(0, 1000) });
  }
  const json = await res.json();
  return JSON.stringify(json);
})();
EOF
)

RAW=$(agent-browser --session "$SESSION" eval "$JS")

# RAW is a JSON string; parse it.
OBJ=$(node -e 'const raw=process.argv[1]; const obj=JSON.parse(raw); if (obj && obj.error) { console.error("Fetch failed:", JSON.stringify(obj, null, 2)); process.exit(3); } console.log(JSON.stringify(obj));' "$RAW")

if [[ -n "$OUT_JSON" ]]; then
  echo "$OBJ" | node -e 'const fs=require("fs"); const data=fs.readFileSync(0,"utf8"); fs.writeFileSync(process.argv[1], JSON.stringify(JSON.parse(data), null, 2));' "$OUT_JSON"
  echo "Wrote JSON: $OUT_JSON" >&2
fi

# 3) Render Markdown report using parse_activities.js
TMP_JSON=$(mktemp)
echo "$OBJ" | node -e 'const fs=require("fs"); const data=fs.readFileSync(0,"utf8"); fs.writeFileSync(process.argv[1], JSON.stringify(JSON.parse(data), null, 2));' "$TMP_JSON"

node "$(dirname "$0")/parse_activities.js" "$TMP_JSON" > "$OUT_MD"
rm -f "$TMP_JSON"

echo "Wrote Markdown: $OUT_MD" >&2

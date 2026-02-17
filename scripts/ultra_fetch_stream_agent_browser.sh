#!/usr/bin/env bash
set -euo pipefail

# Fetch Blackboard Ultra Stream JSON using agent-browser.
#
# This opens a HEADED browser window, you login manually (SSO), then the script
# executes fetch() inside the page to retrieve the JSON.
#
# Usage:
#   ./ultra_fetch_stream_agent_browser.sh --out ./stream.json
#
# Notes:
# - Requires a GUI environment for --headed.
# - Uses a persistent profile dir so your session can survive restarts.

OUT=""
SESSION="blackboard"
PROFILE_DIR="${AGENT_BROWSER_PROFILE:-$HOME/.openclaw/agent-browser-profiles/blackboard}"
URL="https://blackboard.up.edu.mx/ultra/stream"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      OUT="$2"; shift 2;;
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

if [[ -z "$OUT" ]]; then
  echo "Missing --out /path/to/stream.json" >&2
  exit 2
fi

mkdir -p "$(dirname "$OUT")" "$PROFILE_DIR"

echo "Opening Blackboard Stream (you may need to login)..." >&2
agent-browser --session "$SESSION" --profile "$PROFILE_DIR" --headed open "$URL" >/dev/null

cat >&2 <<'MSG'

When you are fully logged in and can see the Stream page,
come back to this terminal and press ENTER.

MSG
read -r _

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

# RAW is a JSON string; write pretty JSON.
node -e 'const fs=require("fs"); const raw=process.argv[1]; const obj=JSON.parse(raw); fs.writeFileSync(process.argv[2], JSON.stringify(obj, null, 2));' "$RAW" "$OUT"

echo "Wrote: $OUT" >&2

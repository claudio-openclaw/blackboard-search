#!/usr/bin/env bash
set -euo pipefail

# One-time login bootstrap for Blackboard + Google SSO.
# Uses agent-browser persistent session/profile and waits for manual 2FA approval when needed.

SESSION="${SESSION:-blackboard}"
PROFILE_DIR="${PROFILE_DIR:-$HOME/.openclaw/agent-browser-profiles/blackboard}"
LOGIN_URL="${LOGIN_URL:-https://blackboard.up.edu.mx/ultra/stream}"
TIMEOUT_SEC="${TIMEOUT_SEC:-240}"

mkdir -p "$PROFILE_DIR"

agent-browser close >/dev/null 2>&1 || true
agent-browser --session "$SESSION" --profile "$PROFILE_DIR" open "$LOGIN_URL" >/dev/null
agent-browser --session "$SESSION" wait 2000 >/dev/null

# Try SSO button when present.
agent-browser --session "$SESSION" click 'a[href*="/auth-saml/saml/login"], text="Iniciar sesión con Google SSO"' >/dev/null 2>&1 || true

start_ts=$(date +%s)
while true; do
  url=$(agent-browser --session "$SESSION" get url || true)
  title=$(agent-browser --session "$SESSION" get title || true)

  # Success condition.
  if [[ "$url" == *"blackboard.up.edu.mx/ultra/stream"* ]] && [[ "$title" == *"Actividad"* || "$title" == *"Activity"* ]]; then
    echo "BLACKBOARD_LOGIN_OK"
    exit 0
  fi

  # 2FA challenge condition (Google device prompt).
  if [[ "$url" == *"accounts.google.com"*"/challenge/"* ]] || [[ "$url" == *"signin/challenge"* ]]; then
    echo "BLACKBOARD_2FA_PENDING"
    echo "Approve Google prompt on your phone, then wait..."
  fi

  now=$(date +%s)
  if (( now - start_ts > TIMEOUT_SEC )); then
    echo "BLACKBOARD_AUTH_REQUIRED"
    exit 2
  fi

  sleep 3
done

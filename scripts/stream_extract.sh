#!/usr/bin/env bash
set -euo pipefail

# Extract Blackboard stream events from current authenticated session.

SESSION="${SESSION:-blackboard}"
OUT_JSON="${OUT_JSON:-/home/openclaw/.openclaw/workspace/out/blackboard/latest.json}"
URL="${URL:-https://blackboard.up.edu.mx/ultra/stream}"

mkdir -p "$(dirname "$OUT_JSON")"

agent-browser --session "$SESSION" open "$URL" >/dev/null
agent-browser --session "$SESSION" wait 3000 >/dev/null

RAW=$(agent-browser --session "$SESSION" eval '(async()=>{const links=[...document.querySelectorAll("a")].map(a=>({text:(a.textContent||"").trim().replace(/\s+/g," "),href:a.href||""})).filter(x=>x.text); return JSON.stringify({title:document.title||"",url:location.href,links});})()')

node - "$RAW" "$OUT_JSON" <<'NODE'
const fs = require('fs');
const crypto = require('crypto');

let raw = JSON.parse(process.argv[2]);
const out = process.argv[3];
if (typeof raw === 'string') raw = JSON.parse(raw);

if (!raw.url || !raw.url.includes('blackboard.up.edu.mx')) {
  console.log('BLACKBOARD_AUTH_REQUIRED');
  process.exit(2);
}

const events = [];
let currentCourse = '';
for (const l of (raw.links || [])) {
  const text = (l.text || '').trim();
  if (!text) continue;
  if ((l.href || '').includes('/ultra/courses/')) {
    currentCourse = text;
    continue;
  }
  if (/^Fecha de vencimiento:/i.test(text)) {
    events.push({ course: currentCourse || 'Curso', type: 'due', text });
  } else if (/^Añadido:/i.test(text)) {
    events.push({ course: currentCourse || 'Curso', type: 'added', text });
  }
}

const uniq = [];
const seen = new Set();
for (const e of events) {
  const key = `${e.course}||${e.type}||${e.text}`;
  if (!seen.has(key)) {
    seen.add(key);
    uniq.push(e);
  }
}

const digest = 'sha256:' + crypto.createHash('sha256').update(JSON.stringify(uniq)).digest('hex');
const payload = {
  generatedAt: new Date().toISOString(),
  source: raw.url,
  title: raw.title || 'Actividad',
  count: uniq.length,
  digest,
  events: uniq,
};

fs.writeFileSync(out, JSON.stringify(payload, null, 2));
console.log('BLACKBOARD_EXTRACT_OK');
console.log(out);
NODE

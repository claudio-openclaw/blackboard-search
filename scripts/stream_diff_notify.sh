#!/usr/bin/env bash
set -euo pipefail

# Compare latest extract against previous state and print machine + human outputs.

LATEST_JSON="${LATEST_JSON:-/home/openclaw/.openclaw/workspace/out/blackboard/latest.json}"
STATE_JSON="${STATE_JSON:-/home/openclaw/.openclaw/workspace/memory/blackboard-watch-state.json}"
REPORT_MD="${REPORT_MD:-/home/openclaw/.openclaw/workspace/reports/blackboard/activities-latest.md}"

mkdir -p "$(dirname "$STATE_JSON")" "$(dirname "$REPORT_MD")"

if [[ ! -f "$LATEST_JSON" ]]; then
  echo "BLACKBOARD_ERROR"
  echo "latest json not found: $LATEST_JSON"
  exit 1
fi

node - "$LATEST_JSON" "$STATE_JSON" "$REPORT_MD" <<'NODE'
const fs = require('fs');

const latestPath = process.argv[2];
const statePath = process.argv[3];
const reportPath = process.argv[4];

const latest = JSON.parse(fs.readFileSync(latestPath, 'utf8'));
let prev = null;
try { prev = JSON.parse(fs.readFileSync(statePath, 'utf8')); } catch {}

const changed = !prev || prev.digest !== latest.digest;
const pending = (latest.events || []).filter(e => e.type === 'due');

const md = [];
md.push('# Blackboard — Actividad reciente');
md.push('');
md.push(`Generado: ${latest.generatedAt}`);
md.push(`Fuente: ${latest.source}`);
md.push('');

if (latest.events.length) {
  md.push(`## Eventos detectados (${latest.events.length})`);
  md.push('');
  for (const e of latest.events) md.push(`- **${e.course}** — ${e.text}`);
} else {
  md.push('## Sin eventos detectados');
  md.push('');
  md.push('- No se encontraron eventos "Fecha de vencimiento" o "Añadido".');
}
md.push('');

if (changed) {
  md.push('## Estado');
  md.push('- Cambios detectados vs ejecución anterior.');
} else {
  md.push('## Estado');
  md.push('- Sin cambios desde la última ejecución.');
}
md.push('');
md.push(`## Pendientes actuales (${pending.length})`);
md.push('');
if (!pending.length) {
  md.push('- No se detectaron pendientes en el stream.');
} else {
  for (const e of pending) {
    md.push(`- **${e.course}** — ${e.text} _(fecha exacta no visible en stream)_`);
  }
}

fs.writeFileSync(reportPath, md.join('\n'));
fs.writeFileSync(statePath, JSON.stringify({
  updatedAt: new Date().toISOString(),
  digest: latest.digest,
  count: latest.count,
  events: latest.events,
}, null, 2));

if (changed) {
  console.log('BLACKBOARD_CHANGED');
  const top = latest.events.slice(0, 8);
  if (!top.length) console.log('- (sin eventos)');
  else for (const e of top) console.log(`- ${e.course}: ${e.text}`);
} else {
  console.log('BLACKBOARD_NO_CHANGES');
}
console.log('PENDIENTES_ACTUALES');
if (!pending.length) console.log('- Ninguno');
else for (const e of pending.slice(0, 8)) console.log(`- ${e.course}: ${e.text} (fecha exacta no visible en stream)`);
console.log('SUGERENCIA_AYUDA: ¿Quieres que te ayude con alguna de estas actividades?');
console.log(reportPath);
NODE

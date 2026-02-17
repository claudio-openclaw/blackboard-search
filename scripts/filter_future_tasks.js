#!/usr/bin/env node
/**
 * Filter normalized tasks to future deadlines and emit clean reports.
 * Usage:
 *   node scripts/filter_future_tasks.js <tasks-json> [--now 2026-02-17T00:00:00-06:00] [--out-dir ./out]
 */
const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
if (!args[0]) {
  console.error('Usage: node scripts/filter_future_tasks.js <tasks-json> [--now ISO] [--out-dir DIR]');
  process.exit(2);
}

const input = args[0];
let outDir = './out';
let now = new Date();
for (let i = 1; i < args.length; i++) {
  if (args[i] === '--now' && args[i + 1]) now = new Date(args[++i]);
  else if (args[i] === '--out-dir' && args[i + 1]) outDir = args[++i];
}

const rows = JSON.parse(fs.readFileSync(input, 'utf8'));
const withDeadline = rows.filter(r => r.deadline && !Number.isNaN(Date.parse(r.deadline)));
const future = withDeadline.filter(r => new Date(r.deadline) >= now)
  .sort((a, b) => new Date(a.deadline) - new Date(b.deadline));

fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(path.join(outDir, 'tasks-future.json'), JSON.stringify(future, null, 2));

let master = '# Reporte maestro (pendientes futuros)\n\n';
for (const r of future) {
  master += `## ${r.title}\n`;
  master += `- Curso: ${r.course}\n`;
  master += `- Tipo: ${r.type || 'unknown'}\n`;
  master += `- Deadline: ${r.deadline}\n`;
  master += `- Puntos: ${r.points ?? 'N/D'}\n`;
  master += `- Intentos: ${r.attempts ?? 'N/D'}\n`;
  master += `- Instrucciones: ${r.instructions || 'sin instrucciones visibles'}\n`;
  if (Array.isArray(r.attachments) && r.attachments.length) {
    master += `- Adjuntos:\n`;
    for (const a of r.attachments) {
      master += `  - ${a.name || 'archivo'} [${a.confidence || 'N/A'}]: ${a.url || 'sin-url'}\n`;
    }
  } else {
    master += `- Adjuntos: ninguno detectado\n`;
  }
  master += '\n';
}
fs.writeFileSync(path.join(outDir, 'reporte-maestro-futuros.md'), master);

let prioritized = '# Reporte priorizado (pendientes futuros)\n\n';
future.forEach((r, i) => {
  prioritized += `${i + 1}. ${r.deadline} — ${r.course} — ${r.title}\n`;
});
fs.writeFileSync(path.join(outDir, 'reporte-priorizado-futuros.md'), prioritized);

let attachments = '# Índice de adjuntos (pendientes futuros)\n\n';
for (const r of future) {
  if (!Array.isArray(r.attachments) || !r.attachments.length) continue;
  attachments += `## ${r.title} (${r.course})\n`;
  for (const a of r.attachments) {
    attachments += `- ${a.name || 'archivo'} [${a.confidence || 'N/A'}]: ${a.url || 'sin-url'}\n`;
  }
  attachments += '\n';
}
fs.writeFileSync(path.join(outDir, 'adjuntos-index-futuros.md'), attachments);

console.log(JSON.stringify({
  now: now.toISOString(),
  input,
  outDir,
  total: rows.length,
  future: future.length,
  files: [
    'tasks-future.json',
    'reporte-maestro-futuros.md',
    'reporte-priorizado-futuros.md',
    'adjuntos-index-futuros.md'
  ]
}, null, 2));

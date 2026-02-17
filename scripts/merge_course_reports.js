#!/usr/bin/env node
/*
 * Merge normalized tasks into markdown report.
 * Usage: node scripts/merge_course_reports.js <normalized-json-file>
 */
const fs = require('fs');
const input = process.argv[2];
if (!input) {
  console.error('Usage: node scripts/merge_course_reports.js <normalized-json-file>');
  process.exit(2);
}
const rows = JSON.parse(fs.readFileSync(input, 'utf8'));

rows.sort((a,b) => {
  const ad = a.deadline ? Date.parse(a.deadline) : Number.MAX_SAFE_INTEGER;
  const bd = b.deadline ? Date.parse(b.deadline) : Number.MAX_SAFE_INTEGER;
  return ad - bd;
});

let md = '# Reporte maestro de tareas (Deep Crawl)\n\n';
for (const r of rows) {
  md += `## ${r.title}\n`;
  md += `- Curso: ${r.course}\n`;
  md += `- Tipo: ${r.type}\n`;
  md += `- Deadline: ${r.deadline || 'N/D'}\n`;
  md += `- Puntos: ${r.points ?? 'N/D'}\n`;
  md += `- Intentos: ${r.attempts ?? 'N/D'}\n`;
  md += `- Estado: ${r.status || 'parcial'}\n`;
  md += `- Instrucciones: ${r.instructions || 'sin instrucciones visibles'}\n`;
  if (Array.isArray(r.attachments) && r.attachments.length) {
    md += `- Adjuntos:\n`;
    for (const a of r.attachments) {
      md += `  - ${a.name || 'archivo'} (${a.confidence || 'N/A'}): ${a.url || 'sin-url'}\n`;
    }
  } else {
    md += `- Adjuntos: ninguno detectado\n`;
  }
  md += '\n';
}

process.stdout.write(md);

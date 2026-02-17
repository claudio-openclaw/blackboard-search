#!/usr/bin/env node
/*
 * Base normalizer for deep-crawl outputs.
 * Input: directory containing JSON files with shape:
 * { course, tasks:[{title,type,deadline,points,attempts,instructions,attachments:[{name,url,confidence}]}] }
 * Output: normalized JSON array
 */
const fs = require('fs');
const path = require('path');

const dir = process.argv[2];
if (!dir) {
  console.error('Usage: node scripts/extract_tasks_from_outline.js <raw-dir>');
  process.exit(2);
}

const files = fs.readdirSync(dir).filter(f => f.endsWith('.json'));
const out = [];

for (const f of files) {
  const full = path.join(dir, f);
  let data;
  try {
    data = JSON.parse(fs.readFileSync(full, 'utf8'));
  } catch {
    continue;
  }
  const course = data.course || path.basename(f, '.json');
  const tasks = Array.isArray(data.tasks) ? data.tasks : [];
  for (const t of tasks) {
    out.push({
      course,
      title: t.title || 'Sin título',
      type: t.type || 'unknown',
      deadline: t.deadline || null,
      points: t.points ?? null,
      attempts: t.attempts ?? null,
      instructions: t.instructions || 'sin instrucciones visibles',
      attachments: Array.isArray(t.attachments) ? t.attachments : [],
      status: t.status || 'parcial'
    });
  }
}

process.stdout.write(JSON.stringify(out, null, 2));

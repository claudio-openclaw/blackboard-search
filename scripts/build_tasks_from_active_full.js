#!/usr/bin/env node
/**
 * Convert Blackboard API raw dump (active-full.json) into normalized tasks JSON.
 * Input shape: { ok, courses:[{ name, courseId, contents:[], columns:[] }] }
 */
const fs = require('fs');

const input = process.argv[2];
if (!input) {
  console.error('Usage: node scripts/build_tasks_from_active_full.js <active-full.json>');
  process.exit(2);
}

const raw = JSON.parse(fs.readFileSync(input, 'utf8'));
const courses = Array.isArray(raw.courses) ? raw.courses : [];
const out = [];

for (const c of courses) {
  const contents = Array.isArray(c.contents) ? c.contents : [];
  const columns = Array.isArray(c.columns) ? c.columns : [];

  const byId = new Map(contents.map(x => [x.id, x]));
  const byParent = new Map();
  for (const item of contents) {
    const p = item.parentId || '__root__';
    if (!byParent.has(p)) byParent.set(p, []);
    byParent.get(p).push(item);
  }

  for (const col of columns) {
    const contentId = col.contentId;
    if (!contentId) continue;

    const item = byId.get(contentId) || {};
    const handler = item?.contentHandler?.id || null;
    const grading = col.grading || {};

    const attachments = [];
    const ch = item.contentHandler || {};

    if (ch.file) {
      attachments.push({
        name: ch.file.fileName || item.title || 'archivo',
        url: ch.file.downloadUrl || '',
        confidence: 'alto'
      });
    }
    if (ch.url?.url) {
      attachments.push({
        name: item.title || col.name || 'enlace',
        url: ch.url.url,
        confidence: 'alto'
      });
    }

    const siblings = byParent.get(item.parentId || '__root__') || [];
    for (const s of siblings) {
      if (s.id === contentId) continue;
      const sh = s.contentHandler || {};
      if (sh.file) {
        attachments.push({
          name: sh.file.fileName || s.title || 'archivo',
          url: sh.file.downloadUrl || '',
          confidence: 'medio'
        });
      }
      if (sh.url?.url) {
        attachments.push({
          name: s.title || 'enlace',
          url: sh.url.url,
          confidence: 'medio'
        });
      }
    }

    const dedup = [];
    const seen = new Set();
    for (const a of attachments) {
      const key = `${a.name}|${a.url}|${a.confidence}`;
      if (seen.has(key)) continue;
      seen.add(key);
      dedup.push(a);
    }

    const instructionsRaw = (item.description || '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();

    out.push({
      course: c.name,
      courseId: c.courseId,
      title: col.name || item.title || 'Sin título',
      type: grading.type || handler || 'unknown',
      deadline: grading.due || null,
      points: col.score?.possible ?? null,
      attempts: grading.attemptsAllowed ?? null,
      instructions: instructionsRaw || 'sin instrucciones visibles',
      attachments: dedup,
      status: (grading.due || instructionsRaw || dedup.length) ? 'completo' : 'parcial',
      contentId
    });
  }
}

process.stdout.write(JSON.stringify(out, null, 2));

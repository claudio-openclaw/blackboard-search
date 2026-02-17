#!/usr/bin/env node
/**
 * Parse Blackboard Learn Ultra stream JSON -> Markdown activities summary.
 *
 * Usage:
 *   node parse_activities.js /path/to/stream.json > out.md
 *
 * Input:
 *   JSON response from POST /learn/api/v1/streams/ultra
 *
 * Output:
 *   Markdown grouped by course, sorted by dueDate/startDate when available.
 */

const fs = require("node:fs");

const WANTED_PREFIXES = [
  "UA:", // Ultra assessment-ish
  "AS:", // Assignment
  "TE:", // Test
  "PS:", // Assessment
  "SU:", // Survey/Self-assessment
  "QU:", // Quiz
  "SC:", // SCORM / some graded content
  "GB:", // Gradebook due/overdue
];

function parseISO(s) {
  if (!s || typeof s !== "string") return null;
  const d = new Date(s);
  return Number.isNaN(d.getTime()) ? null : d;
}

function fmtUTC(d) {
  if (!d) return "-";
  // YYYY-MM-DD HH:mm UTC
  const pad = (n) => String(n).padStart(2, "0");
  return `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())} ${pad(d.getUTCHours())}:${pad(d.getUTCMinutes())} UTC`;
}

function courseMap(obj) {
  const courses = obj?.sv_extras?.sx_courses || [];
  const m = new Map();
  for (const c of courses) {
    if (!c?.id) continue;
    m.set(c.id, {
      name: c.name || c.id,
      url: c.externalAccessUrl || "",
    });
  }
  return m;
}

function extractActivities(obj) {
  const entries = obj?.sv_streamEntries || [];
  const out = [];

  for (const e of entries) {
    const extra = e?.extraAttribs || {};
    const ev = extra.event_type;
    if (!ev || !WANTED_PREFIXES.some((p) => ev.startsWith(p))) continue;

    const item = e?.itemSpecificData || {};
    const notif = item?.notificationDetails || {};

    const courseId = notif.courseId || e.se_courseId || "(unknown-course)";
    const title = item.title || "(sin título)";

    const due = parseISO(notif.dueDate);
    const start = parseISO(notif.startDate);

    out.push({
      courseId,
      eventType: ev,
      title,
      due,
      start,
      sourceType: notif.sourceType,
      courseContentId: item.courseContentId,
    });
  }

  return out;
}

function toMarkdown(obj) {
  const courses = courseMap(obj);
  const acts = extractActivities(obj);
  const byCourse = new Map();

  for (const a of acts) {
    const cid = a.courseId || "(unknown-course)";
    if (!byCourse.has(cid)) byCourse.set(cid, []);
    byCourse.get(cid).push(a);
  }

  const sortKey = (a) => {
    const due = a.due ? a.due.toISOString() : "9999";
    const start = a.start ? a.start.toISOString() : "9999";
    return `${due}|${start}`;
  };

  const lines = [];
  lines.push("# Blackboard — Actividades (Learn Ultra)");
  lines.push("");
  lines.push(`Fuente: streams/ultra (entries=${(obj?.sv_streamEntries || []).length})`);
  lines.push("");

  const courseIds = Array.from(byCourse.keys()).sort();
  for (const cid of courseIds) {
    const meta = courses.get(cid) || { name: cid, url: "" };
    lines.push(`## ${meta.name}`);
    if (meta.url) {
      lines.push("");
      lines.push(meta.url);
    }

    const items = byCourse.get(cid).slice().sort((a, b) => (sortKey(a) < sortKey(b) ? -1 : 1));
    for (const a of items) {
      lines.push(`- [${a.eventType}] ${a.title} (due: ${fmtUTC(a.due)}; start: ${fmtUTC(a.start)})`);
    }
    lines.push("");
  }

  return lines.join("\n").trimEnd() + "\n";
}

function main() {
  const file = process.argv[2];
  if (!file) {
    console.error("Usage: node parse_activities.js /path/to/stream.json");
    process.exit(2);
  }
  const raw = fs.readFileSync(file, "utf8");
  const obj = JSON.parse(raw);
  process.stdout.write(toMarkdown(obj));
}

main();

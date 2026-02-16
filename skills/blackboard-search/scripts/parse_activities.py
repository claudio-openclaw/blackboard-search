#!/usr/bin/env python3
"""Parse Blackboard Learn Ultra stream JSON -> Markdown activities summary.

Usage:
  python3 parse_activities.py /path/to/stream.json > out.md

Input:
  JSON response from POST /learn/api/v1/streams/ultra (like example.json)

Output:
  Markdown grouped by course, sorted by dueDate/startDate when available.

Notes:
  - This script does NOT make network calls.
  - Intended to be paired with a browser-session fetch (evaluate(fetch)).
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

WANTED_PREFIXES = (
    "UA:",  # Ultra assessment-ish
    "AS:",  # Assignment
    "TE:",  # Test
    "PS:",  # Assessment
    "SU:",  # Survey/Self-assessment
    "QU:",  # Quiz
    "SC:",  # SCORM / some graded content
    "GB:",  # Gradebook due/overdue
)


def _parse_iso(ts: Optional[str]) -> Optional[datetime]:
    if not ts:
        return None
    try:
        # Example: 2024-08-15T05:59:59.000Z
        if ts.endswith("Z"):
            ts = ts[:-1] + "+00:00"
        return datetime.fromisoformat(ts)
    except Exception:
        return None


def _fmt_dt(dt: Optional[datetime]) -> str:
    if not dt:
        return "-"
    # show in local-ish naive format; caller can adjust
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")


def _course_map(obj: Dict[str, Any]) -> Dict[str, Dict[str, str]]:
    courses = obj.get("sv_extras", {}).get("sx_courses", []) or []
    m: Dict[str, Dict[str, str]] = {}
    for c in courses:
        cid = c.get("id")
        if not cid:
            continue
        m[cid] = {
            "name": c.get("name") or cid,
            "url": c.get("externalAccessUrl") or "",
        }
    return m


def extract_activities(obj: Dict[str, Any]) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    for e in obj.get("sv_streamEntries", []) or []:
        extra = e.get("extraAttribs", {}) or {}
        ev = extra.get("event_type")
        if not ev or not any(ev.startswith(p) for p in WANTED_PREFIXES):
            continue

        item = e.get("itemSpecificData", {}) or {}
        notif = item.get("notificationDetails", {}) or {}

        course_id = notif.get("courseId") or e.get("se_courseId")
        title = item.get("title") or "(sin título)"

        due_dt = _parse_iso(notif.get("dueDate"))
        start_dt = _parse_iso(notif.get("startDate"))

        out.append(
            {
                "courseId": course_id,
                "eventType": ev,
                "title": title,
                "due": due_dt,
                "start": start_dt,
                "sourceType": notif.get("sourceType"),
                "courseContentId": item.get("courseContentId"),
            }
        )
    return out


def to_markdown(obj: Dict[str, Any]) -> str:
    courses = _course_map(obj)
    acts = extract_activities(obj)

    # group by course
    by_course: Dict[str, List[Dict[str, Any]]] = {}
    for a in acts:
        cid = a.get("courseId") or "(unknown-course)"
        by_course.setdefault(cid, []).append(a)

    def sort_key(a: Dict[str, Any]) -> Tuple[str, str]:
        # sort by due then start; missing last
        due = a.get("due")
        start = a.get("start")
        due_s = due.isoformat() if isinstance(due, datetime) else "9999"
        start_s = start.isoformat() if isinstance(start, datetime) else "9999"
        return (due_s, start_s)

    lines: List[str] = []
    lines.append("# Blackboard — Actividades (Learn Ultra)")
    lines.append("")
    lines.append(f"Fuente: streams/ultra (entries={len(obj.get('sv_streamEntries', []) or [])})")
    lines.append("")

    for cid in sorted(by_course.keys()):
        course_name = courses.get(cid, {}).get("name", cid)
        course_url = courses.get(cid, {}).get("url", "")
        header = f"## {course_name}"
        if course_url:
            header += f"\n\n{course_url}"
        lines.append(header)

        items = sorted(by_course[cid], key=sort_key)
        for a in items:
            due_s = _fmt_dt(a.get("due"))
            start_s = _fmt_dt(a.get("start"))
            ev = a.get("eventType")
            title = a.get("title")
            # Keep it compact
            lines.append(f"- [{ev}] {title} (due: {due_s}; start: {start_s})")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: parse_activities.py /path/to/stream.json", file=sys.stderr)
        return 2

    path = Path(sys.argv[1])
    obj = json.loads(path.read_text())
    sys.stdout.write(to_markdown(obj))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

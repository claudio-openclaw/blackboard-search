---
name: blackboard-search
description: Search and retrieve content from Blackboard Learn (announcements, course materials, assignments, grades, messages, and files). Use when the user asks to “search Blackboard”, “find X in the course”, “locate the announcement/assignment/document”, “what does the syllabus say”, or when you need to navigate Blackboard’s UI to locate a specific resource inside a course.
---

# Blackboard Search

## Goal

Quickly locate content inside Blackboard (globally or within a specific course) using guided navigation + in-UI search, without asking for passwords in chat.

## Recommended fast flow

1) **Ensure you have a session**
- Open Blackboard in the browser using the `browser` tool.
- If the user says they already have it open in Chrome (with the extension/Browser Relay), use **profile="chrome"** and ask them to **attach the tab** (badge ON) before attempting any clicks.
- If there is no active session, **ask the user to sign in manually** (SSO). Do not request passwords.

2) **Choose scope**
- **Inside a course**: when the user mentions a specific class/course.
- **Global**: when they don’t know which course contains the resource.

3) **Search**
- Try Blackboard’s **built-in search** first (if available in that view).
- If search is missing/limited, use:
  - **Content Collection / Files / Course Content** + search/filters
  - **Ctrl/Cmd+F** to find text on long pages

4) **Deliver a useful result**
- Provide: the **exact click path** (e.g., “Courses → X → Course Content → Week 3 → PDF …”), a **link** if available, and **what you found**.
- When applicable, include: **due date**, **deliverable**, **weight/rubric** (if visible).
- If the user asks you to “download” or “upload/submit”, ask for confirmation before downloading/uploading files.

## Playbooks by request type

### A) “Find X in course Y”
1. Go to **Courses** → open **course Y**.
2. Check first:
   - **Announcements** (if it sounds like a notice)
   - **Course Content / Content / Materials** (if it sounds like a file)
   - **Assignments** (if it sounds like an assignment)
   - **Syllabus / Course Information** (if it sounds like a syllabus/overview)
3. Use search inside that section (if available) or navigate modules/weeks.
4. If it’s not there, open the course’s **Files/Content Collection** and search by name/type.

### B) “I don’t know which course it’s in”
1. Go to the main landing page (course list).
2. Try **global search** (if the instance supports it).
3. If global search is not effective:
   - Ask the user for a shortlist of the 3–6 most likely courses
   - Repeat playbook A using the file name/keywords.

### C) “Tell me what it says / summarize it” (syllabus, announcement, assignment instructions)
1. Open the resource.
2. Extract what matters (titles, dates, rubric, deliverables).
3. If it’s long: summarize in bullets and highlight **deadlines and requirements**.

## UI notes (fragility)

- Blackboard labels vary (“Course Content” vs “Content” vs “Materials”). Prioritize **intent-based navigation**, not exact labels.
- If something fails due to UI differences, take a `browser.snapshot` (ideally `refs="aria"`) and look for:
  - Inputs with placeholder “Search”
  - The course side navigation
  - Sections like: Announcements / Assignments / Grades / Messages / Files

## Scripts (automation-ready)

Use these scripts to run Blackboard checks with persistent session + deterministic outputs:

- `scripts/login_bootstrap.sh`
  - One-time bootstrap for Blackboard + Google SSO.
  - Waits for manual 2FA approval when required.
  - Output status: `BLACKBOARD_LOGIN_OK` | `BLACKBOARD_2FA_PENDING` | `BLACKBOARD_AUTH_REQUIRED`.

- `scripts/stream_extract.sh`
  - Extracts stream events from `/ultra/stream` into canonical JSON.
  - Default output file: `/home/openclaw/.openclaw/workspace/out/blackboard/latest.json`.
  - Output status: `BLACKBOARD_EXTRACT_OK` | `BLACKBOARD_AUTH_REQUIRED`.

- `scripts/stream_diff_notify.sh`
  - Compares latest extract vs previous digest, writes markdown report, updates state.
  - Default state: `/home/openclaw/.openclaw/workspace/memory/blackboard-watch-state.json`.
  - Default report: `/home/openclaw/.openclaw/workspace/reports/blackboard/activities-latest.md`.
  - Output status: `BLACKBOARD_CHANGED` | `BLACKBOARD_NO_CHANGES` | `BLACKBOARD_ERROR`.

- `scripts/watch_pipeline.sh`
  - Orchestrates full flow: `login_bootstrap` (only if auth is required) → `stream_extract` → `stream_diff_notify`.
  - Designed for cron use.

### Canonical JSON shape (`latest.json`)

```json
{
  "generatedAt": "ISO-8601",
  "source": "https://blackboard.up.edu.mx/ultra/stream",
  "title": "Actividad",
  "count": 2,
  "digest": "sha256:...",
  "events": [
    { "course": "...", "type": "due|added", "text": "..." }
  ]
}
```

## References

- If you need heuristics for UI elements and common labels, see: `references/blackboard-ui.md`.

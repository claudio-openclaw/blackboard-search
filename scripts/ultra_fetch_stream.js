#!/usr/bin/env node
/**
 * ultra_fetch_stream.js
 *
 * This script prints a ready-to-run JavaScript snippet that you can execute
 * INSIDE an authenticated Blackboard Ultra page (e.g. /ultra/stream) to fetch
 * the Ultra Stream JSON without copying cookies out of your browser.
 *
 * Why: Blackboard is SSO and session-bound; safest pattern is: login manually,
 * then run fetch() in the same session context.
 *
 * Usage:
 *   node ultra_fetch_stream.js > fetch-ultra-stream-snippet.js
 *
 * Then:
 *   1) Open https://blackboard.up.edu.mx/ultra/stream
 *   2) Login (SSO)
 *   3) Open DevTools Console
 *   4) Paste the snippet
 *   5) It will print JSON (you can copy/save it as stream.json)
 */

const payload = {
  providers: {
    bb_tel: {
      sp_provider: "bb_tel",
      sp_newest: -1,
      sp_oldest: 9007199254740992,
      sp_refreshDate: 0,
    },
    bb_deployment: {
      sp_provider: "bb_deployment",
      sp_newest: -1,
      sp_oldest: 9007199254740992,
      sp_refreshDate: Date.now(),
    },
    // Often useful for content/activity notifications:
    "bb-nautilus": {
      sp_provider: "bb-nautilus",
      sp_newest: -1,
      sp_oldest: 9007199254740992,
      sp_refreshDate: Date.now(),
    },
  },
  forOverview: false,
  retrieveOnly: true,
  flushCache: false,
};

const snippet = `// Blackboard Ultra Stream fetch snippet\n// Paste into DevTools console on https://blackboard.up.edu.mx/ultra/stream\n(async () => {\n  const payload = ${JSON.stringify(payload, null, 2)};\n  const res = await fetch("/learn/api/v1/streams/ultra", {\n    method: "POST",\n    headers: {\n      "Content-Type": "application/json;charset=UTF-8",\n      "Accept": "application/json",\n    },\n    credentials: "include",\n    body: JSON.stringify(payload),\n  });\n  if (!res.ok) {\n    const txt = await res.text().catch(() => "");\n    throw new Error(`HTTP ${res.status} ${res.statusText}\\n${txt.slice(0, 500)}`);\n  }\n  const json = await res.json();\n  // Copy from console to a file called stream.json\n  console.log(JSON.stringify(json, null, 2));\n})();\n`;

process.stdout.write(snippet);

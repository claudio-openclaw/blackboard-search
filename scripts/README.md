# Scripts — blackboard-search

## 1) Modo rápido: Stream → Markdown

```bash
./scripts/blackboard_activities.sh --out-md ./blackboard-activities.md
```

Opcional JSON + MD:

```bash
./scripts/blackboard_activities.sh --out-json ./stream.json --out-md ./blackboard-activities.md
```

## 2) Modo profundo: Deep Crawl (base)

```bash
./scripts/crawl_courses_deep.sh --out-dir ./out/deep
```

### Auto-fetch real desde Blackboard (nuevo)

Con sesión ya autenticada en `agent-browser`:

```bash
TERM_PREFIX=ML26PRIMAVERA ./scripts/fetch_raw_from_blackboard.sh --out-dir ./out/deep --session blackboard
```

Esto genera:
- `./out/deep/raw/active-full.json`

Luego puedes correr el pipeline completo:

```bash
./scripts/run_deep_crawl.sh --raw-dir ./out/deep/raw --out-dir ./out --now 2026-02-17T00:00:00-06:00
```

### Pipeline todo-en-uno

```bash
./scripts/run_deep_crawl.sh --raw-dir ./out/deep/raw --out-dir ./out
```

Con fecha de corte explícita:

```bash
./scripts/run_deep_crawl.sh --raw-dir ./out/deep/raw --out-dir ./out --now 2026-02-17T00:00:00-06:00
```

### Pipeline paso a paso (manual)

Normaliza:

```bash
node ./scripts/extract_tasks_from_outline.js ./out/deep/raw > ./out/deep/normalized/tasks.json
```

Consolida a reporte maestro:

```bash
node ./scripts/merge_course_reports.js ./out/deep/normalized/tasks.json > ./out/reporte-maestro.md
```

Filtra pendientes futuros y genera reportes limpios:

```bash
node ./scripts/filter_future_tasks.js ./out/deep/normalized/tasks.json --out-dir ./out
```

## Adjuntos de tareas (PDF/DOC/PPT)

Modelo esperado por tarea:

```json
{
  "title": "Trabajo X",
  "attachments": [
    {"name": "instrucciones.pdf", "url": "https://...", "confidence": "alto"}
  ]
}
```

- `alto`: adjunto dentro del ítem
- `medio`: adjunto en mismo módulo
- `bajo`: adjunto cercano pero ambiguo

## Fallbacks

- `Missing X server or $DISPLAY` → usar `DISPLAY=:1` (Xvfb)
- `401 API request is not authenticated` → reloguear SSO
- `TypeError: Failed to fetch` → usar `agent-browser snapshot` y extraer desde UI

## Nota sobre paralelismo

Blackboard + SSO puede invalidar sesiones en workers paralelos. Preferir barrido secuencial robusto por curso.

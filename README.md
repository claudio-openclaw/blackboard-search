# blackboard-search

Skill para buscar y auditar tareas en Blackboard Learn Ultra, incluyendo instrucciones y adjuntos (ej. PDF de actividad).

## Capacidades

- Pendientes rápidos desde Stream (`Próximo/Hoy/Reciente`).
- Deep crawl curso-por-curso para extraer tareas completas.
- Detección de adjuntos por actividad (PDF/DOC/PPT/enlaces).
- Salida normalizada para priorizar entregas.

## Requisitos

- Sesión SSO activa de Blackboard.
- `agent-browser`.
- Node.js.
- En hosts headless: Xvfb (`DISPLAY=:1`).

## Login / SSO

- No se piden contraseñas por chat.
- Se puede hacer click en Google SSO y esperar confirmación del usuario.
- Si aparece `401`, sesión expirada/no iniciada.

## Quickstart

### 1) Modo rápido (pendientes)

```bash
./scripts/blackboard_activities.sh --out-md ./blackboard-activities.md
```

### 2) Modo profundo (todas las tareas)

```bash
./scripts/crawl_courses_deep.sh --out-dir ./out/deep
node ./scripts/merge_course_reports.js ./out/deep > ./out/reporte-maestro.md
```

> El deep crawl es secuencial robusto por curso: Blackboard/SSO suele romper paralelismo real.

## Qué entrega el reporte profundo

Por tarea:
- curso
- título y tipo
- deadline
- puntos/intentos
- instrucciones resumidas
- adjuntos + URL
- confianza del vínculo (`alto|medio|bajo`)
- estado (`completo|parcial`)

## Fallbacks

- `Missing X server or $DISPLAY` → usar `DISPLAY=:1`
- `401 API request is not authenticated` → reloguear SSO
- `TypeError: Failed to fetch` → fallback a lectura por `agent-browser snapshot`
- si no hay texto de instrucciones → marcar “sin instrucciones visibles”

## Estructura

- `SKILL.md` — flujo operativo del skill.
- `scripts/blackboard_activities.sh` — stream quick report.
- `scripts/crawl_courses_deep.sh` — deep crawl base.
- `scripts/extract_tasks_from_outline.js` — extracción/normalización.
- `scripts/merge_course_reports.js` — consolidación.
- `scripts/README.md` — guía de scripts.

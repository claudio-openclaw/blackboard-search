# blackboard-search

Skill para buscar y recuperar contenido de Blackboard Learn Ultra (anuncios, tareas, materiales, mensajes, calificaciones y pendientes) sin pedir credenciales por chat.

## Qué hace

- Navega Blackboard por curso o de forma global.
- Ubica recursos por intención (tarea, syllabus, anuncio, PDF, etc.).
- Extrae pendientes desde el Stream (`Próximo/Hoy/Reciente`).
- Puede convertir actividad del stream a reporte Markdown con scripts locales.

## Requisitos

- Sesión SSO válida de Blackboard.
- `agent-browser` para navegación automatizada.
- Node.js para scripts (`parse_activities.js`, `ultra_fetch_stream.js`).
- En hosts headless: Xvfb disponible (normalmente con `DISPLAY=:1`).

## Quickstart

### 1) Obtener pendientes rápidamente en UI

1. Abrir `https://blackboard.up.edu.mx/ultra/stream`.
2. Asegurar que hay sesión iniciada (nombre del usuario visible en navbar).
3. Si falla el endpoint del stream, usar `agent-browser snapshot` y leer pendientes directamente de la UI.

### 2) Reporte automático Markdown

```bash
./scripts/blackboard_activities.sh --out-md ./blackboard-activities.md
```

Opcional (también guardar JSON):

```bash
./scripts/blackboard_activities.sh --out-json ./stream.json --out-md ./blackboard-activities.md
```

## Login / Autenticación (SSO)

- Nunca pedir contraseñas por chat.
- Si hay botón de Google SSO, se puede hacer click por UI y esperar aprobación del usuario en su dispositivo.
- Si aparece `401 API request is not authenticated`, la sesión expiró o no inició.

## Ejemplos de uso

- “¿Qué pendientes tengo en Blackboard?”
- “Encuentra el syllabus de Hackeo Ético.”
- “Ubica el PDF de fortalecimiento de contraseñas.”
- “Resúmeme las instrucciones de la tarea X.”

## Troubleshooting

- `Missing X server or $DISPLAY`:
  - usar `DISPLAY=:1` si existe Xvfb.
- `401 API request is not authenticated`:
  - re-login en `/ultra/stream`.
- `TypeError: Failed to fetch` al llamar `/learn/api/v1/streams/ultra`:
  - fallback inmediato: extraer pendientes vía `agent-browser snapshot` del Stream.

## Estructura del repo

- `SKILL.md` — guía principal de operación del skill.
- `scripts/blackboard_activities.sh` — flujo end-to-end (login + fetch + Markdown).
- `scripts/ultra_fetch_stream.js` — snippet DevTools para obtener stream JSON.
- `scripts/ultra_fetch_stream_agent_browser.sh` — fetch de stream con agent-browser.
- `scripts/parse_activities.js` — parser JSON → Markdown.
- `scripts/README.md` — documentación de scripts.
- `references/` — notas y guías de UI/endpoint.

# blackboard-search

Skill para buscar y extraer contenido de Blackboard Learn Ultra (UP), con fallback por UI cuando falla la API.

## Qué hace

- Encuentra anuncios, tareas, materiales, syllabus y calificaciones.
- Extrae pendientes desde `Flujo de actividades`.
- Si falla `/learn/api/v1/streams/ultra` (`401` o `TypeError: Failed to fetch`), usa extracción por UI.

## Flujo recomendado

1. Abrir `https://blackboard.up.edu.mx/ultra/stream`
2. Iniciar sesión por SSO (sin pedir contraseñas por chat)
3. Intentar extracción API
4. Si falla, fallback UI (`Próximo`)
5. Entregar resultados con ruta, fecha y contexto

## Scripts

- `scripts/blackboard_activities.sh` — E2E (login + fetch + markdown)
- `scripts/ultra_fetch_stream.js` — snippet de DevTools
- `scripts/ultra_fetch_stream_agent_browser.sh` — fetch con agent-browser
- `scripts/parse_activities.js` — JSON a markdown

## Skill

Ver instrucciones operativas en `SKILL.md`.

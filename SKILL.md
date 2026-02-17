---
name: blackboard-search
description: Search and retrieve content from Blackboard Learn Ultra (announcements, assignments, syllabus, grades, messages, files) and extract upcoming tasks. Use when user asks to find something in Blackboard, summarize course content, locate due dates, or sync Blackboard tasks into Obsidian/TaskNotes.
---

# Blackboard Search

Repositorio oficial: `https://github.com/claudio-openclaw/blackboard-search`

Objetivo: encontrar rápido contenido real en Blackboard y entregar resultado accionable (ruta exacta, enlace y resumen).

## Protocolo obligatorio (orden fijo)

1. **Abrir Blackboard**
   - Ir a `https://blackboard.up.edu.mx/ultra/stream`.
   - Verificar sesión con señales UI (nombre del usuario + menú Cursos/Calendario).

2. **Si no hay sesión, resolver login sin pedir credenciales**
   - Click en SSO (Google) y esperar que el usuario termine login.
   - Nunca pedir password por chat.

3. **Intentar extracción por API Ultra Stream**
   - Usar `fetch('/learn/api/v1/streams/ultra', { method:'POST', credentials:'include', ... })` desde la página.

4. **Si API falla (`401` o `TypeError: Failed to fetch`), usar fallback UI (obligatorio)**
   - No bloquearse.
   - Extraer tareas de la sección **Próximo** en `Flujo de actividades` con `agent-browser snapshot` / `get text body`.
   - Reportar igual aunque no haya JSON.

5. **Entregar siempre formato útil**
   - Curso
   - Título de tarea/recurso
   - Fecha/hora de entrega (si existe)
   - Ruta de clics exacta
   - URL (si existe)

## Flujos por tipo de solicitud

### A) "Encuentra X en curso Y"
1. Ir a `Cursos` → abrir curso.
2. Revisar en orden: `Announcements` → `Course Content` → `Assignments` → `Syllabus`.
3. Si no aparece, revisar `Files/Content Collection`.
4. Devolver ruta exacta + hallazgo.

### B) "No sé en qué curso está"
1. Probar búsqueda global si existe.
2. Si no, revisar cursos probables y repetir flujo A.
3. Pedir al usuario acotar si hay demasiados cursos.

### C) "Resúmelo"
1. Abrir recurso.
2. Extraer entregables, rúbrica, restricciones y fechas.
3. Responder en bullets cortos con énfasis en fechas.

### D) "Pásalo a Obsidian/TaskNotes"
1. Obtener pendientes por API o fallback UI.
2. Mapear curso Blackboard → materia de `UP/Semestres/**` por similitud.
3. Crear/actualizar notas en formato TaskNotes en `TaskNotes/Tasks`.
4. Incluir siempre detalles (curso, fuente, due, tipo de evento, hash).

## Definition of done

La tarea está completa solo si entregas:
- Hallazgo verificable (o confirmación explícita de "sin resultados"),
- Ruta de navegación reproducible,
- Fechas de entrega cuando existan,
- Y, si se pidió, nota creada/actualizada en Obsidian TaskNotes.

## Errores comunes → acción inmediata

- `Missing X server or $DISPLAY`
  - Usar sesión que ya tenga navegador activo; si no, correr en entorno con display.
- `401 API request is not authenticated`
  - Sesión expirada: reabrir Stream y relogin SSO.
- `TypeError: Failed to fetch`
  - Saltar a fallback UI y extraer pendientes desde `Próximo`.

## Scripts disponibles

- `scripts/blackboard_activities.sh` — flujo E2E (login + extracción + markdown)
- `scripts/ultra_fetch_stream.js` — snippet para DevTools
- `scripts/ultra_fetch_stream_agent_browser.sh` — fetch con agent-browser
- `scripts/parse_activities.js` — stream JSON → markdown

## Regla de oro

Si la API falla pero la UI muestra pendientes, **la tarea NO está bloqueada**. Extraer de UI y seguir.
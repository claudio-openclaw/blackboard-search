---
name: blackboard-search
description: Search and retrieve content from Blackboard Learn (Ultra) (announcements, course materials, assignments, grades, messages, and files). Use when the user asks to “buscar en Blackboard”, “encuentra X en el curso”, “ubica el anuncio/tarea/documento”, “qué dice el syllabus”, or when you need to navigate Blackboard’s UI to locate a specific resource inside a course.
metadata: {"openclaw":{"emoji":"🎓"}}
---

# Blackboard Search

## Cuándo usar este skill

Usa este skill cuando el usuario pida encontrar o resumir información de Blackboard Ultra:
- pendientes / fechas de entrega
- tareas / anuncios / syllabus
- materiales (PDF, archivos, links)
- mensajes o calificaciones dentro de Blackboard

## Objetivo

Encontrar rápido contenido dentro de Blackboard (global o por curso) usando navegación guiada + búsqueda en UI, sin exponer secretos ni pedir contraseñas por chat.

## Flujo recomendado

1) **Asegurar sesión SSO**
- Abrir Blackboard con `agent-browser`.
- Si no hay sesión activa, pedir login manual SSO (sin pedir password).
- En host headless con Xvfb: usar `DISPLAY=:1` + `agent-browser --headed`.
- Si existe botón de Google SSO, puede clickearse por UI y esperar aprobación del usuario.

2) **Elegir alcance**
- **Curso específico**: cuando el usuario menciona materia.
- **Global**: cuando no sabe en qué curso está el recurso.

3) **Buscar**
- Primero usar búsqueda nativa de Blackboard (si existe en esa vista).
- Si no, navegar por secciones: Announcements, Course Content/Materials, Assignments, Files/Content Collection.
- En páginas largas, usar búsqueda textual (`snapshot` + encontrar texto clave).

4) **Entregar resultado útil**
- Responder con ruta exacta (clics), hallazgo y link cuando exista.
- Si pidió descargar/subir archivos, confirmar antes.

## Fallbacks (importante)

Si el endpoint de stream falla (`401` o `TypeError: Failed to fetch`):
- no bloquearse en API,
- usar `agent-browser snapshot` en `/ultra/stream`,
- extraer pendientes desde “Próximo/Hoy/Reciente” y reportar igual.

## Playbook por tipo de pedido

### A) “Encuentra X en el curso Y”
1. Ir a **Courses** → abrir **curso Y**.
2. Revisar: Announcements, Course Content/Materials, Assignments, Syllabus/Course Information.
3. Buscar por keyword dentro de la sección.
4. Si no aparece, ir a Files/Content Collection del curso.

### B) “No sé en qué curso está”
1. Ir a vista principal de cursos.
2. Intentar búsqueda global.
3. Si no sirve, acotar a 3–6 cursos probables y repetir flujo A.

### C) “Dime qué dice / resúmelo”
1. Abrir recurso.
2. Extraer puntos clave (fechas, entregables, rúbrica, formato).
3. Resumir en bullets y resaltar requisitos críticos.

## Límites y seguridad

- No pedir ni procesar contraseñas por chat.
- No inventar contenido si no aparece en Blackboard.
- Reportar incertidumbre cuando la UI esté incompleta o cambie etiquetas.

## Scripts disponibles

- `scripts/blackboard_activities.sh` — end-to-end; el usuario solo inicia sesión y genera reporte Markdown.
- `scripts/ultra_fetch_stream.js` — snippet para DevTools (fetch del Ultra Stream).
- `scripts/ultra_fetch_stream_agent_browser.sh` — fetch del Stream con agent-browser (headed).
- `scripts/parse_activities.js` — JSON stream → Markdown.
- `scripts/README.md` — guía de uso de scripts.

## Troubleshooting rápido

- **`Missing X server or $DISPLAY`**: usar `DISPLAY=:1` si hay Xvfb.
- **`401 API request is not authenticated`**: sesión expirada o no iniciada; reloguear en `/ultra/stream`.
- **`TypeError: Failed to fetch`**: usar fallback por `snapshot` de UI.
- Señales de sesión válida: nombre de usuario en navbar, cursos visibles, cards en “Próximo/Hoy/Reciente”.

## Referencias

- `references/blackboard-ui.md`
- `references/guide-ultra-stream.md`

---
name: blackboard-search
description: Search and retrieve content from Blackboard Learn (Ultra) (announcements, course materials, assignments, grades, messages, and files). Use when the user asks to “buscar en Blackboard”, “encuentra X en el curso”, “ubica el anuncio/tarea/documento”, “qué dice el syllabus”, or when you need to navigate Blackboard’s UI to locate a specific resource inside a course.
metadata: {"openclaw":{"emoji":"🎓"}}
---

# Blackboard Search

## Cuándo usar este skill

- “¿Qué pendientes tengo en Blackboard?”
- “Revísame todas las tareas de todos mis cursos”
- “Dime la descripción completa de cada actividad”
- “Ubica el PDF con instrucciones de la tarea X”

## Objetivo

Extraer tareas reales (no inventadas) desde Blackboard Ultra con suficiente detalle para decidir qué hacer: fecha, tipo, puntos, intentos, instrucciones y adjuntos (PDF/DOC/PPT/enlaces).

## Modos de trabajo

### Modo rápido (stream)
Usar cuando el usuario solo quiere pendientes inmediatos.
- `/ultra/stream`
- leer `Próximo/Hoy/Reciente`
- entregar resumen corto

### Modo profundo (deep crawl)
Usar cuando el usuario pida “todas las tareas”, “todas las descripciones”, o auditoría completa por curso.
- recorrer curso por curso en `Contenido`
- expandir módulos y `Cargar más`
- abrir cada actividad evaluable
- capturar metadatos + instrucciones + adjuntos

## Flujo recomendado (deep crawl)

1) **Asegurar sesión SSO**
- abrir Blackboard con `agent-browser`
- no pedir contraseñas por chat
- en host headless con Xvfb: usar `DISPLAY=:1`

2) **Enumerar cursos activos**
- obtener cursos abiertos de la vista `Cursos`
- priorizar período actual

3) **Recorrer contenido por curso**
- abrir `Contenido`
- expandir todos los bloques
- detectar actividades evaluables (assessment, formulario, debate, quiz, etc.)

4) **Entrar a cada actividad**
Extraer:
- título
- tipo
- deadline
- puntos
- intentos
- reglas (late submissions, cierre de intentos)
- instrucciones visibles

5) **Capturar adjuntos por actividad**
- detectar PDF/DOC/PPT/enlaces
- guardar nombre + URL
- marcar confianza de vínculo:
  - `alto`: adjunto dentro del ítem
  - `medio`: adjunto en el mismo módulo
  - `bajo`: adjunto cercano pero ambiguo

6) **Salida estandarizada**
- Curso
- Tarea
- Tipo
- Deadline
- Puntos/Intentos
- Resumen de instrucciones
- Adjuntos (links)
- Confianza del vínculo
- Estado (`completo` / `parcial`)

## Fallbacks obligatorios

- `401 API request is not authenticated` → reloguear SSO
- `TypeError: Failed to fetch` en endpoint de stream → fallback a `snapshot` UI
- si no hay instrucciones en overview → intentar rutas alternas y módulo padre
- si no hay texto utilizable → reportar “sin instrucciones visibles”

## Límites y seguridad

- nunca pedir credenciales por chat
- no inventar instrucciones o fechas
- indicar incertidumbre explícita cuando Blackboard oculte contenido

## Scripts disponibles

- `scripts/blackboard_activities.sh` — quick report del stream
- `scripts/crawl_courses_deep.sh` — orquesta deep crawl por cursos (base)
- `scripts/extract_tasks_from_outline.js` — normaliza tareas desde JSON/snapshots
- `scripts/merge_course_reports.js` — consolida reportes por curso
- `scripts/README.md` — cómo ejecutar y cómo interpretar salida

## Referencias

- `references/blackboard-ui.md`
- `references/guide-ultra-stream.md`

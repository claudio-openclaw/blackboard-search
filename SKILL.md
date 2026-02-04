---
name: blackboard-search
description: Search and retrieve content from Blackboard Learn (announcements, course materials, assignments, grades, messages, and files). Use when the user asks to “buscar en Blackboard”, “encuentra X en el curso”, “ubica el anuncio/tarea/documento”, “qué dice el syllabus”, or when you need to navigate Blackboard’s UI to locate a specific resource inside a course.
---

# Blackboard Search

## Objetivo

Encontrar rápido contenido dentro de Blackboard (global o por curso) usando navegación guiada + búsqueda en la UI, sin pedir contraseñas por chat.

## Flujo recomendado (rápido)

1) **Asegurar sesión**
- Abrir Blackboard en el navegador con la tool `browser`.
- Si no hay sesión activa, **pedir al usuario que inicie sesión manualmente** (SSO). No solicitar passwords.

2) **Elegir alcance**
- **Dentro de un curso**: cuando el usuario menciona una materia/curso.
- **Global**: cuando no sabe en qué curso está el recurso.

3) **Buscar**
- Probar primero **búsqueda propia de Blackboard** (si existe en esa vista).
- Si no aparece o es limitada, usar:
  - **“Content Collection / Files / Course Content”** + búsqueda/filtros
  - **Ctrl/Cmd+F** para ubicar texto dentro de páginas largas

4) **Entregar resultado útil**
- Enviar: **ruta/clics exactos** (ej. “Courses → X → Course Content → Week 3 → PDF …”), **link** si existe, y **qué encontró**.
- Si el usuario pidió “descargar”, pedir confirmación antes de descargar/subir archivos.

## Playbook por tipo de pedido

### A) “Encuentra X en el curso Y”
1. Ir a **Courses** → abrir **curso Y**.
2. Revisar primero:
   - **Announcements** (si suena a aviso)
   - **Course Content / Content / Materials** (si suena a archivo)
   - **Assignments** (si suena a tarea)
   - **Syllabus / Course Information** (si suena a temario)
3. Usar búsqueda en esa sección (si existe) o navegar por módulos/semanas.
4. Si no aparece, ir a **Files/Content Collection** del curso y buscar por nombre/tipo.

### B) “No sé en qué curso está”
1. Ir a la vista principal (lista de cursos).
2. Intentar **búsqueda global** (si la instancia la tiene).
3. Si no hay búsqueda global efectiva:
   - Tomar lista corta de 3–6 cursos más probables (preguntar al usuario cuáles)
   - Repetir flujo A con búsqueda por nombre/keyword.

### C) “Dime qué dice / resúmelo” (syllabus, anuncio, instrucciones de tarea)
1. Abrir el recurso.
2. Copiar lo esencial (títulos, fechas, rubricas, entregables).
3. Si es largo: resumir con bullets y resaltar **fechas y requisitos**.

## Notas de UI (fragilidad)
- Blackboard cambia labels (“Course Content” vs “Content” vs “Materials”). Priorizar **búsqueda por intención**, no por label exacto.
- Si algo falla por UI distinta, hacer `browser.snapshot` y buscar por:
  - Inputs con placeholder “Search”
  - Menús laterales del curso
  - Secciones: Announcements / Assignments / Grades / Messages / Files

## Referencias
- Si necesitas heurísticas de elementos UI y palabras comunes por idioma, leer: `references/blackboard-ui.md`.

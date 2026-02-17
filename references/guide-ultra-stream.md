# Blackboard Learn Ultra — Guía para sacar información (actividades + asistencia)

> **Objetivo:** obtener información de Blackboard Learn Ultra sin “copiar cookies al chat”.
> La estrategia recomendada es: **login manual → requests hechas dentro del browser (misma sesión) → limpiar/parsear → output legible**.

## 0) Seguridad (importante)

- **Nunca pegues cookies/tokens en un chat** (JSESSIONID, BbRouter, XSRF, samlCookie, etc.).
  Eso equivale a entregar tu sesión.
- Si ya las pegaste, **trátalo como comprometido**:
  - cierra sesión en Blackboard
  - borra cookies del sitio
  - si tu cuenta usa SSO, considera cerrar sesión en el IdP / invalidar sesiones.

En esta guía, **no guardamos cookies** ni las imprimimos; solo usamos la sesión activa del navegador.

---

## 1) Prerrequisitos

- Blackboard Learn Ultra (UP): `https://blackboard.up.edu.mx/`
- Estar logueado en el navegador.
- Tener acceso a la página de **Stream**: `https://blackboard.up.edu.mx/ultra/stream`

---

## 2) Endpoint clave: Ultra Stream

### 2.1 URL

- `POST https://blackboard.up.edu.mx/learn/api/v1/streams/ultra`

### 2.2 Headers relevantes (conceptualmente)

En tu ejemplo se ve:

- `Content-Type: application/json;charset=UTF-8`
- `Accept: application/json`
- `X-Blackboard-XSRF: <token>`
- `Suppress-Session-Timestamp-Update: true` (opcional)

**Ojo:** en implementación real no hardcodeamos esto; el browser ya trae cookies/headers necesarios.

### 2.3 Body (payload)

El request usa `providers` para seleccionar qué “feeds” quieres.
Ejemplo mínimo (como el tuyo):

```json
{
  "providers": {
    "bb_tel": {
      "sp_provider": "bb_tel",
      "sp_newest": -1,
      "sp_oldest": 9007199254740992,
      "sp_refreshDate": 0
    },
    "bb_deployment": {
      "sp_provider": "bb_deployment",
      "sp_newest": -1,
      "sp_oldest": 9007199254740992,
      "sp_refreshDate": 1770178831512
    }
  },
  "forOverview": false,
  "retrieveOnly": true,
  "flushCache": false
}
```

En la práctica, conviene pedir también `bb-nautilus` (ahí caen muchos eventos de contenido/actividades).

---

## 3) Cómo hacer la request sin extraer cookies

### 3.1 Opción recomendada: `browser.act → evaluate(fetch)`

Flujo:
1) Abrir `https://blackboard.up.edu.mx/ultra/stream`
2) Usuario hace login manual (SSO)
3) Ejecutar en el contexto de la página:

Pseudocódigo (conceptual):

```js
async function fetchUltraStream(payload) {
  const res = await fetch("/learn/api/v1/streams/ultra", {
    method: "POST",
    headers: { "Content-Type": "application/json;charset=UTF-8" },
    body: JSON.stringify(payload),
    credentials: "include",
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}
```

Notas:
- `credentials:"include"` hace que el fetch use cookies de la sesión.
- El token XSRF normalmente está disponible en cookies/headers que el browser ya sabe mandar; si Blackboard exige header explícito, se puede leer del storage/cookie **dentro del evaluate**.

---

## 4) Qué datos salen del JSON (ejemplo `example.json`)

Tu output (`/home/openclaw/example.json`) trae principalmente:

### 4.1 Cursos

En `sv_extras.sx_courses[]`:
- `id` (ej. `_87532_1`)
- `name` (nombre humano)
- `externalAccessUrl` (url del curso)

Esto sirve para mapear `courseId → nombre`.

### 4.2 Entradas del stream (eventos)

En `sv_streamEntries[]`:
- `providerId` (frecuente: `bb-nautilus`)
- `se_courseId`
- `se_timestamp`
- `extraAttribs.event_type` (ej. `UA:OVERDUE`, `UA:UA_AVAIL`, `CO:CO_AVAIL`, etc.)
- `itemSpecificData.title`
- `itemSpecificData.notificationDetails.dueDate` (a veces)
- `itemSpecificData.notificationDetails.startDate`
- `itemSpecificData.notificationDetails.sourceType`
- `itemSpecificData.courseContentId`

**Heurística para “actividades”**:
- típicamente `sourceType` / `event_type` con prefijos:
  - `UA:` (Ultra Assignment-ish)
  - `AS:` (Assignment)
  - `TE:` (Test)
  - `PS:` (Assessment)
  - `SU:` (Survey/Self-assessment)
  - `QU:` (Quiz)

---

## 5) Transformación: JSON → output legible (actividades)

### 5.1 Normalización sugerida

Para cada `sv_streamEntries[]` que parezca actividad:
- `courseId`
- `courseName` (lookup en `sx_courses`)
- `title`
- `eventType` (`extraAttribs.event_type`)
- `dueDate` (si existe)
- `startDate` (si existe)
- `contentId` (`courseContentId`)

### 5.2 Presentación en Markdown (ejemplo)

```md
## Actividades (próximas / pendientes)

### Ingeniería de Software_1556
- [UA:OVERDUE] Tarea X — vence: 2026-02-10 23:59
- [TE:DUE] Quiz 2 — vence: 2026-02-06 08:00
```

---

## 6) Asistencia (pendiente de endpoint)

**Asistencia** no viene en tu `example.json` (stream). En Ultra normalmente está en otro endpoint.

Para implementar asistencia, necesitamos **uno**:
- un `attendance.json` de ejemplo, o
- capturar una vez el endpoint exacto en Network (ya logueado) y documentarlo aquí.

Checklist para capturarlo:
1) Ir al curso → sección Attendance/Asistencia
2) Abrir DevTools → Network → filtrar por `attendance` / `gradebook` / `members`
3) Identificar request XHR/fetch que trae JSON
4) Repetir el mismo patrón: `browser.evaluate(fetch)` y parse.

---

## 7) Qué queda por hacer (en la skill)

- [ ] Crear scripts en `skills/blackboard-search/scripts/`:
  - `ultra_fetch_stream.js` (ejecuta el fetch dentro de browser)
  - `parse_activities.py` (convierte JSON → markdown)
  - `parse_attendance.py` (cuando tengamos endpoint)
- [ ] Agregar un “comando” operativo en el playbook:
  - “Saca actividades y asistencia de todos los cursos”
  - o “solo de curso X”

---

## Anexo A: Providers útiles (observados)

En tu ejemplo aparece `sv_providers[]` con:
- `bb-nautilus` (muy útil para eventos)
- `bb_mygrades`
- `bb-announcement`
- `bb_calendar`
- etc.

La selección exacta depende de qué quieras consultar.

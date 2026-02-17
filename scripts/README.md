# Scripts — blackboard-search

Estos scripts son helpers locales para **sacar JSON** de Blackboard Learn Ultra (usando tu sesión logueada) y para **convertir ese JSON a Markdown**.

---

## 1) Obtener el JSON del Stream (Ultra)

### Opción A (simple): `ultra_fetch_stream.js` (snippet para DevTools)

1. Abre: https://blackboard.up.edu.mx/ultra/stream
2. Inicia sesión (SSO)
3. Abre DevTools → Console
4. Genera el snippet:

```bash
node scripts/ultra_fetch_stream.js
```

5. Pégalo en la consola y copia el JSON a un archivo (ej. `stream.json`).

### Opción B (semi-automático): `ultra_fetch_stream_agent_browser.sh`

Automatiza el `fetch()` dentro del browser con **agent-browser** (modo `--headed`).

```bash
./scripts/ultra_fetch_stream_agent_browser.sh --out ./stream.json
```

> Requiere ambiente con GUI para abrir el navegador en modo headed.
> En hosts headless con Xvfb, usa `DISPLAY=:1` al ejecutar `agent-browser`.

---

## 2) Convertir JSON → Markdown (actividades)

### parse_activities.js

```bash
node scripts/parse_activities.js ./stream.json > ./blackboard-activities.md
```

> Nota: este parser no hace requests. Está pensado para usarse junto con el fetch dentro del browser (misma sesión logueada).

---

## Fallback recomendado (si falla fetch API)

Si `/learn/api/v1/streams/ultra` devuelve `401` o `TypeError: Failed to fetch`, no te bloquees:
1. Abre `/ultra/stream` con sesión activa.
2. Ejecuta `agent-browser snapshot`.
3. Extrae pendientes desde secciones **Próximo / Hoy / Reciente**.

## 3) Todo-en-uno (lo único que haces es login)

```bash
./scripts/blackboard_activities.sh --out-md ./blackboard-activities.md
```

Si también quieres guardar el JSON:

```bash
./scripts/blackboard_activities.sh --out-json ./stream.json --out-md ./blackboard-activities.md
```

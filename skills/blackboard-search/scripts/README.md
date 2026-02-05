# Scripts — blackboard-search

Estos scripts son helpers locales para convertir JSON de Blackboard (Learn Ultra) a Markdown.

## parse_activities.py

Convierte el JSON de `POST /learn/api/v1/streams/ultra` en un resumen Markdown por curso.

```bash
python3 scripts/parse_activities.py /home/openclaw/example.json > out/blackboard-activities.md
```

> Nota: este script no hace requests. Está pensado para usarse junto con el fetch dentro del browser (misma sesión logueada).

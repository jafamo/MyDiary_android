# Backend MyDiary — contexto para la app

Resumen del backend y de su API orientado a construir la app. **La referencia exacta es `/home/jfarinos/Projects/MyDiary/doc/openapi.json`**; si este documento discrepa, manda `openapi.json` y se corrige aquí. Estado descrito: backend `0.18.1` (fases 1–7 de su `ROADMAP.md` publicadas).

## Qué hace el backend

Aplicación Symfony (PHP 8.4, PostgreSQL + pgvector, Redis + Messenger) de un solo usuario:

1. Recibe notas de voz por **Telegram** o por **subida desde la app** (`POST /api/v1/audios`).
2. Un worker asíncrono las **transcribe** con Whisper (Open WebUI). Estado del audio: `PENDING` → `TRANSCRIBED`, o `ERROR` si se agotan los reintentos (con `error_code` / `error_message`, reintentable).
3. A las **21:00 Europe/Madrid** genera el **resumen del día** con Ollama (texto, temas y leyenda de emojis). También bajo demanda, de forma asíncrona. Entre 21:00 y 00:30 lo regenera si llegan audios nuevos.
4. A las **08:00** avisa por Telegram de los recordatorios del día.
5. **Búsqueda semántica** (embeddings) en transcripciones y resúmenes, y por texto en recordatorios.

Los avisos (transcripción lista o fallida, resumen, recordatorios) **hoy solo salen por Telegram**, también para audios subidos desde la app. Push es la fase 8 del backend, pendiente.

## Autenticación

- `POST /api/v1/login` con `{"username", "password", "device_name"}` → `200` con `token` (64 hex, **solo se devuelve aquí**), `token_id`, `device_name`, `expires_at`.
- Resto de peticiones: `Authorization: Bearer <token>`.
- Token opaco por dispositivo; caduca a los **90 días sin uso** y cada uso lo renueva. No hay refresh token: al caducar o revocarse, cualquier petición da `401` → volver al login.
- `POST /api/v1/logout` → `204`, revoca el token en uso. `GET /api/v1/me` → `username`, `token_id`, `device_name`, `created_at`, `last_used_at`, `expires_at`.
- Login limitado a **5 intentos / 15 min** por IP y usuario → `429` con `Retry-After`.
- El usuario sale siempre del token, nunca de un parámetro.

## Convenciones

- JSON con claves en `snake_case`.
- **Instantes** (`received_at`, `created_at`, `generated_at`...): ISO 8601 UTC, `2026-10-08T07:09:33Z`. Convertir a local solo para mostrar.
- **Días** (`date`, `month`): `AAAA-MM-DD` / `AAAA-MM` en `Europe/Madrid`. Son fechas de calendario: no aplicar zona horaria. "Hoy" lo decide el servidor (campo `date` de `/diario`).
- **Paginación:** `page` (desde 1) y `per_page` (20 por defecto, máx. 100). Respuesta `{items, page, per_page, total}`. Pasada la última página, `items` vacío con el `total` real.
- **Parámetros inválidos** → `422` (el backend no los ignora, a diferencia de la web).
- **Errores:** siempre `{"code", "message"}`. Códigos estables: `bad_request` 400, `unauthorized` 401, `forbidden` 403, `not_found` 404, `method_not_allowed` 405, `conflict` 409, `validation_failed` 422, `too_many_requests` 429, `internal_error` 500. `message` está en castellano y se puede mostrar.
- **Cuerpos `PATCH`:** los campos ausentes no cambian. Campo desconocido, obligatorio vacío o valor no transformable → `422` con mensaje que nombra el campo.
- Excepción: un cuerpo de más de 30 MB lo corta nginx con un `413` en **HTML**, fuera del formato de error.

## Recursos (esquemas de `openapi.json`)

- **Audio**: `id`, `status` (`PENDING`|`TRANSCRIBED`|`ERROR`), `source` (`telegram`|`app`), `duration_seconds`, `received_at`; en detalle además `error_code`, `error_message`, `transcription` (o `null`).
- **Transcription**: `id`, `content`, `edited_manually`, `model`, `processing_ms`, `created_at`, `updated_at`.
- **Summary**: `id`, `date`, `summary_text`, `generated_at`, `emoji_legend`, `topics` (`[Topic]`), `model`, `prompt_tokens`, `completion_tokens`, `generation_ms` (métricas pueden ser `null` en registros antiguos → mostrar "—").
- **SummaryGeneration**: `status` (`QUEUED`|`RUNNING`|`DONE`|`FAILED`), `requested_at`, `started_at`, `finished_at`, `error_code`, `error_message`. Una generación atascada (>15 min) llega como `FAILED` con `error_code` `STALLED` y se puede volver a pedir.
- **Topic**: `id`, `name`. **Reminder**: `id`, `date`, `time` (`HH:MM` o `null`), `text`, `created_at`, `updated_at`.
- **Statistics**: ver endpoint de estadísticas.

Nunca se exponen rutas de ficheros, embeddings, `content_hash` ni identificadores de Telegram.

## Endpoints

### Lectura

| Endpoint | Equivale a (web) | Notas |
|---|---|---|
| `GET /api/v1/diario?status=` | Diario | `date`, `entries` (`[Audio]` detalle), `summary`, `summary_generation`, `streak {current, best}`, `week {total, delta}`, `top_topic {name, count}` |
| `GET /api/v1/historial?month=AAAA-MM` | Calendario | `month`, `previous_month`, `next_month`, `days [{date, audio_count, has_summary}]` (solo días con datos; la rejilla la pinta la app) |
| `GET /api/v1/historial/{fecha}?status=` | Día del historial | audios y resumen; día vacío = `200` con listas vacías |
| `GET /api/v1/resumenes?from=&to=&page=&per_page=` | Resúmenes | paginado, del más reciente al más antiguo, con `audio_count`; `from`/`to` los dos o ninguno |
| `GET /api/v1/busqueda?q=` | Búsqueda | `query`, `results [{type: transcription\|daily_summary, distance, date, audio, summary}]` (menor `distance` = más parecido), `reminders [Reminder]`. Si falla el embedding, `results` vacío pero `reminders` sí llega |
| `GET /api/v1/estadisticas?range=&from=&to=&status=` | Estadísticas | `range`: `15`, `30` (defecto), `90`, `365` o `custom` con `from`/`to`. Series crudas (`series`, `reminders_series` como `[{date, value}]`), totales, medias, `status_counts`, `topic_frequency`, rachas, `record_day`, `previous_period_comparison`, `ai_usage {totals, days}`. Los gráficos los dibuja la app |
| `GET /api/v1/recordatorios?scope=\|month=\|date=` | Recordatorios | paginado; un solo filtro: `scope` (`upcoming` defecto / `history`), `month` o `date` |
| `GET /api/v1/recordatorios/proximos` | Campana | `count` (próximos 5 días), `level` (`urgent` hoy/mañana, `upcoming`, `null`), `nearest_date`, `reminders` (los del día más cercano) |
| `GET /api/v1/topics` | Temas | `{items: [Topic + usage_count, last_used], total}`, sin paginar |

### Escritura

| Endpoint | Respuesta | Reglas |
|---|---|---|
| `PATCH /api/v1/audios/{id}/transcripcion` `{"content"}` | `200` Audio | solo `TRANSCRIBED`, si no `409`. Marca `edited_manually` y regenera el embedding |
| `DELETE /api/v1/audios/{id}` | `204` | solo `TRANSCRIBED` o `ERROR` (`PENDING` = `409`). Irreversible: confirmar en la app |
| `POST /api/v1/audios/{id}/reintentar` | `200` Audio en `PENDING` | solo `ERROR`, si no `409` |
| `POST /api/v1/recordatorios` `{"date", "time"?, "text"}` | `201` Reminder | |
| `PATCH /api/v1/recordatorios/{id}` | `200` Reminder | parcial; `"time": null` quita la hora |
| `DELETE /api/v1/recordatorios/{id}` | `204` | |
| `PATCH /api/v1/topics/{id}` `{"name"}` | `200` Topic | `409` si otro tema ya usa ese nombre (sin distinguir mayúsculas) → ofrecer fusionar |
| `POST /api/v1/topics/fusionar` `{"origins": [ids], "destination": id}` | `200` Topic destino | irreversible, el backend no pide confirmación: la pide la app |

### Resumen bajo demanda

`POST /api/v1/diario/resumen` (sin cuerpo) → `202` con un `SummaryGeneration` (si ya había uno en curso, devuelve ese). `409` si hoy no hay transcripciones. La app **sondea** `GET /api/v1/diario` (la web lo hace cada 5 s) hasta que `summary_generation.status` sea `DONE` o `FAILED`. Mientras esté `QUEUED`/`RUNNING`, el botón de generar va desactivado.

### Audio: subida

`POST /api/v1/audios`, `multipart/form-data`, fichero en el campo **`file`**.

- Formatos aceptados **por contenido** (ffprobe en servidor, no cuenta la extensión ni el `Content-Type`): `m4a`, `mp3`, `ogg`, `wav`. **Máximo 25 MB.** La app graba en **AAC `.m4a`**.
- La duración la calcula el servidor; no se envía.
- Respuesta: Audio breve + `result`: `created` (`201`), `duplicate` (`200`, mismo SHA-256 ya subido, no se toca) o `retrying` (`200`, existía en `ERROR` y se relanza). Esto hace que **reintentar una subida sea seguro** (idempotente por contenido).
- `422 validation_failed` si falta el fichero, llega incompleto, supera 25 MB o no es audio admitido.
- Tras subirlo, el audio queda `PENDING` y se transcribe en segundo plano: la app refresca `/diario` para ver el cambio de estado (no hay push todavía).

### Audio: reproducción

`GET /api/v1/audios/{id}/fichero` con el Bearer → fichero original, `Content-Type` por extensión (`audio/ogg`, `audio/mp4`, `audio/mpeg`, `audio/wav`), `Cache-Control: private, max-age=86400`. Admite **`Range`** (`206`; `416` fuera de rango) → reproducción con salto. `404` si no existe o falta el fichero en disco.

**Limitación conocida:** los audios de Telegram son **Ogg/Opus** y se sirven sin convertir. Android (ExoPlayer) los reproduce; **iOS (AVPlayer) no**. Mientras no se resuelva en el backend (convertir a `.m4a` con el `ffmpeg` que ya tiene la imagen PHP, opción preferida), en iOS los audios con `source = telegram` no se podrán reproducir. No resolverlo en la app con un reproductor alternativo sin decidirlo antes.

## Herramientas del backend útiles desde aquí

- Swagger UI: `<base_url>/doc/api` (pide sesión web, no token).
- Peticiones de ejemplo: `/home/jfarinos/Projects/MyDiary/doc/api.http` y `doc/MyDiary.postman_collection.json`.
- Tokens emitidos por dispositivo: `bin/console app:user:token:list <username>` / `app:user:token:revoke <id>` (en el contenedor `diary-php`).
- Backend local: `make up` en el repo del backend; API en `http://localhost:9008` (`http://10.0.2.2:9008` desde el emulador de Android).

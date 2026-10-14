# Roadmap — app móvil MyDiary

> Plan de la app (Android primero, iOS con el mismo código). Sin fechas comprometidas. Cada fase es un `openspec change` propio con su rama Git Flow (ver `AGENTS.md`); al abordarla, marcarla aquí con el nombre del change. La API que consume ya existe (fases 1–7 del `ROADMAP.md` del backend); ver `doc/BACKEND.md`.

## Decisiones abiertas

Se deciden al proponer la fase correspondiente (regla «Opciones de diseño antes de implementar» de `AGENTS.md`).

- ~~**D1 — Gestión de estado**~~ — decidida: **Riverpod sin generación de código** (`AsyncValue` para cargando/error/datos).
- ~~**D2 — Navegación**~~ — decidida: **`go_router`** (redirección al login, enlaces profundos para push).
- ~~**D3 — Modelos**~~ — decidida: **`fromJson` escritos a mano**, uno por esquema de `openapi.json`.
- **D4 — Audios Ogg/Opus de Telegram en iOS** (antes de la fase iOS): convertir a `.m4a` en el backend (preferida) o reproductor alternativo en la app (`media_kit`, sin confirmar soporte de Opus en iOS).
- **D5 — Push** (fase 7): el backend preveía APNs directo porque «solo hay iPhone»; con Android, FCM (`firebase_messaging`) cubre las dos plataformas. Revisar D5 del backend.
- **D6 — Subidas sin cobertura** (fase 3): subir solo en primer plano con reintento manual, o cola local persistente con subida en segundo plano (`background_downloader`). La subida es idempotente por contenido, así que reintentar es seguro.

## Fases

### Fase 0 — Esqueleto ✅

> Hecha en el change `project-skeleton` (rama `feature/project-skeleton`). Toolchain en Docker (Flutter 3.47.7, JDK 21, SDK de Android). Modelos de los recursos (`Audio`, `Transcription`, `Summary`, `SummaryGeneration`, `Topic`, `Reminder`, `Paginated`); las respuestas propias de cada endpoint se modelan en la fase que las usa.

`flutter create` (Android + iOS), análisis estático y formato, CI, configuración por `--dart-define`, `ApiClient` (Bearer, errores `{code, message}`, `401` → login), modelos de la API con tests de parseo. D1–D3.

### Fase 1 — Login

Login (`username`, `password`, `device_name` del dispositivo), token en `flutter_secure_storage`, `GET /me` al arrancar, logout. `429` con `Retry-After`.

### Fase 2 — Diario (lectura)

Portada con las entradas de hoy, estado de cada audio, transcripción, resumen, rachas, semana y tema del mes. Filtro por estado. Pull-to-refresh.

### Fase 3 — Grabar y subir

Grabación AAC `.m4a` (`record`), permisos de micrófono, subida multipart, resultado `created` / `duplicate` / `retrying`. D6.

### Fase 4 — Escuchar

Reproductor con salto (`just_audio` + Bearer + `Range`).

### Fase 5 — Resto de lectura

Historial (calendario propio), Resúmenes, Búsqueda, Recordatorios (+ campana), Estadísticas (gráficos en la app), Temas.

### Fase 6 — Escritura

Editar/eliminar transcripción, reintentar audio en `ERROR`, generar resumen con sondeo de estado, CRUD de recordatorios, renombrar y fusionar temas (con confirmación en la app).

### Fase 7 — Notificaciones push

Depende de la fase 8 del backend (registro de dispositivos y notificador). D5.

### Fase 8 — iOS

Build y firma para iPhone, permisos (`NSMicrophoneUsageDescription`), ATS, D4. Compilar para iOS requiere Xcode, es decir, macOS: no se puede desde esta máquina Linux.

- **D7 — Dónde compilar iOS:** un Mac propio (con Apple ID gratuito, instalar por cable con `flutter run`; la app caduca a los 7 días) o compilar en la nube (Codemagic o GitHub Actions con macOS) y distribuir por TestFlight. TestFlight y push (fase 7) requieren la cuenta de Apple Developer de pago.

Mientras tanto, el desarrollo se prueba en el emulador de Android en Docker (`make emulator-up`).

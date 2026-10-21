# Roadmap — app móvil MyDiary

> Plan de la app (Android primero, iOS con el mismo código). Sin fechas comprometidas. Cada fase es un `openspec change` propio con su rama Git Flow (ver `AGENTS.md`); al abordarla, marcarla aquí con el nombre del change. La API que consume ya existe (fases 1–7 del `ROADMAP.md` del backend); ver `doc/BACKEND.md`.

## Decisiones abiertas

Se deciden al proponer la fase correspondiente (regla «Opciones de diseño antes de implementar» de `AGENTS.md`).

- ~~**D1 — Gestión de estado**~~ — decidida: **Riverpod sin generación de código** (`AsyncValue` para cargando/error/datos).
- ~~**D2 — Navegación**~~ — decidida: **`go_router`** (redirección al login, enlaces profundos para push).
- ~~**D3 — Modelos**~~ — decidida: **`fromJson` escritos a mano**, uno por esquema de `openapi.json`.
- **D4 — Audios Ogg/Opus de Telegram en iOS** (antes de la fase iOS): convertir a `.m4a` en el backend (preferida) o reproductor alternativo en la app (`media_kit`, sin confirmar soporte de Opus en iOS).
- **D5 — Push** (fase 7): el backend preveía APNs directo porque «solo hay iPhone»; con Android, FCM (`firebase_messaging`) cubre las dos plataformas. Revisar D5 del backend.
- ~~**D6 — Subidas sin cobertura**~~ — decidida: **sin cola**. Si la subida falla, la hoja de grabación conserva la nota con «Reintentar» mientras la app siga abierta; al cerrarla se pierde. La nota queda con la fecha de la subida (el backend no recibe la hora de grabación), aceptado.

## Fases

### Fase 0 — Esqueleto ✅

> Hecha en el change `project-skeleton` (rama `feature/project-skeleton`). Toolchain en Docker (Flutter 3.47.7, JDK 21, SDK de Android). Modelos de los recursos (`Audio`, `Transcription`, `Summary`, `SummaryGeneration`, `Topic`, `Reminder`, `Paginated`); las respuestas propias de cada endpoint se modelan en la fase que las usa.

`flutter create` (Android + iOS), análisis estático y formato, CI, configuración por `--dart-define`, `ApiClient` (Bearer, errores `{code, message}`, `401` → login), modelos de la API con tests de parseo. D1–D3.

### Fase 1 — Login ✅

> Hecha en el change `login` (rama `feature/login`). Pantalla de carga mientras se valida la sesión con `/me` (sin red se entra con la guardada), `device_name` automático (fabricante, modelo y versión del sistema), menú ⋮ con la cuenta y «Cerrar sesión». Probado en el emulador contra el backend local, incluida la revocación del token por consola.

Login (`username`, `password`, `device_name` del dispositivo), token en `flutter_secure_storage`, `GET /me` al arrancar, logout. `429` con `Retry-After`.

### Fase 2 — Diario (lectura) ✅

> Hecha en el change `diary` (rama `feature/diary`). Portada con el resumen arriba (plegable), cifras compactas, filtro por estado y entradas con «Ver más». Recarga sola cada 10 s mientras hay algo en curso (en primer plano y con la pestaña visible), al deslizar y al volver a la app. Barra inferior con Diario, Historial, Buscar y Más (las tres últimas, provisionales hasta la fase 5). App en español (`flutter_localizations`, `intl`).

Portada con las entradas de hoy, estado de cada audio, transcripción, resumen, rachas, semana y tema del mes. Filtro por estado. Pull-to-refresh.

### Fase 3 — Grabar y subir ✅

> Hecha en el change `recording` (rama `feature/recording`). Botón 🎙 en el Diario que abre una hoja inferior con tiempo, nivel de entrada, Pausa, Descartar y Enviar. AAC-LC `.m4a` en mono a 64 kbps, máximo de 45 min, pantalla encendida mientras graba y pausa al salir de la app. Subida con progreso y aviso según `result`; si falla, «Reintentar» desde la hoja (D6: sin cola). Micrófono del PC en el emulador.

Grabación AAC `.m4a` (`record`), permisos de micrófono, subida multipart, resultado `created` / `duplicate` / `retrying`. D6.

### Fase 4 — Escuchar ✅

> Hecha en el change `playback` (rama `feature/playback`). Botón ▶ en cada entrada del Diario; la nota se descarga entera con el token (sin pasar el token al reproductor ni proxy local) y el fichero se borra al terminar. Reproductor dentro de la tarjeta con salto y velocidad (1×, 1,5×, 2×), un audio cada vez. Sigue sonando en segundo plano con controles en la notificación y la pantalla de bloqueo (`audio_service` + `just_audio`). Grabar pausa la escucha.

Reproductor con salto (`just_audio` + Bearer + `Range`).

### Fase 5 — Resto de lectura

> Historial hecho en el change `history` (rama `feature/history`): calendario propio de lunes a domingo con pastilla del nº de notas y punto si hay resumen, cambio de mes con ‹/› y deslizando; pantalla del día (`/historial/:fecha`) con resumen, filtro y notas con ▶, y flechas al día con notas anterior y siguiente (`previous_date`/`next_date`, requieren un backend posterior a 0.19.0).
>
> Resúmenes hechos en el change `summaries` (rama `feature/summaries`): «Más» pasa a ser un menú; lista de resúmenes plegados (fecha, nº de audios y tres líneas) que se despliegan con la leyenda, los temas y las métricas de la IA, chip de audios que abre el día del Historial, scroll infinito y filtro por rango de fechas.
>
> Búsqueda hecha en el change `search` (rama `feature/search`): se busca al enviar (no mientras se escribe), recordatorios arriba y notas y resúmenes del más parecido al menos, con ▶, «Ver más» y «Ver día»; sin búsquedas recientes guardadas.
>
> Pendiente: Recordatorios, Estadísticas y Temas.

Historial (calendario propio), Resúmenes, Búsqueda, Recordatorios (+ campana), Estadísticas (gráficos en la app), Temas.

### Fase 6 — Escritura

Editar/eliminar transcripción, reintentar audio en `ERROR`, generar resumen con sondeo de estado, CRUD de recordatorios, renombrar y fusionar temas (con confirmación en la app).

### Fase 7 — Notificaciones push

Depende de la fase 8 del backend (registro de dispositivos y notificador). D5.

### Fase 8 — iOS

Build y firma para iPhone, permisos (`NSMicrophoneUsageDescription`), ATS, D4. Compilar para iOS requiere Xcode, es decir, macOS: no se puede desde esta máquina Linux.

- **D7 — Dónde compilar iOS:** un Mac propio (con Apple ID gratuito, instalar por cable con `flutter run`; la app caduca a los 7 días) o compilar en la nube (Codemagic o GitHub Actions con macOS) y distribuir por TestFlight. TestFlight y push (fase 7) requieren la cuenta de Apple Developer de pago.

Mientras tanto, el desarrollo se prueba en el emulador de Android en Docker (`make emulator-up`).

### Publicación en Google Play (preparada, sin publicar)

> Preparada en el change `android-release` (rama `feature/android-release`): firma de release, icono, `PRIVACY.md` y guía en `doc/RELEASE.md` (prueba interna). Publicar queda aplazado hasta que se decida.

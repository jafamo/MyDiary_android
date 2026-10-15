# Changelog

Todos los cambios relevantes de la app se documentan aquí. Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y versionado [SemVer](https://semver.org/lang/es/) sin prefijo `v`.

## [Sin publicar]

### Ramas integradas en develop

- `feature/project-skeleton` — fase 0 del roadmap.
- `feature/android-emulator` — emulador de Android opcional en Docker.
- `feature/login` — fase 1 del roadmap.
- `feature/diary` — fase 2 del roadmap.
- `feature/recording` — fase 3 del roadmap.
- `feature/playback` — fase 4 del roadmap.
- `feature/history` — fase 5 del roadmap: Historial.

### Añadido

- `AGENTS.md`, `CLAUDE.md`, `ROADMAP.md` y `doc/BACKEND.md` con el contexto del backend MyDiary y las reglas del repositorio.
- Toolchain en Docker (Flutter 3.47.7, JDK 21, SDK de Android): imagen `mydiary-flutter`, contenedor de larga duración con la red del host y `Makefile` (`build`, `up`, `get`, `format`, `format-check`, `analyze`, `test`, `apk`, `run`, `adb-pair`, `adb-connect`...).
- Proyecto Flutter para Android e iOS (`com.jfarinos.mydiary`), con HTTP en claro solo en el build de debug.
- Configuración por `--dart-define-from-file` (`env/<entorno>.json`, no versionado; ejemplo en `env.example.json`). Sin `API_BASE_URL` válida, la app muestra un error de configuración.
- `ApiClient` sobre `dio`: `/api/v1`, `Authorization: Bearer`, errores como `ApiException` con `code` estable (`network_error` e `invalid_response` del lado cliente), aviso de sesión caducada ante un `401` (salvo en el login) y `Retry-After` en el `429`.
- Modelos `Audio`, `Transcription`, `Summary`, `SummaryGeneration`, `Topic`, `Reminder` y `Paginated`, con instantes en UTC y días de calendario sin zona horaria.
- Navegación con `go_router` y estado con Riverpod: rutas `/splash`, `/login` y secciones principales con redirección según la sesión.
- Emulador de Android 36 en Docker, opcional y solo de desarrollo (perfil `emulator`, no lo arranca `make up`): ventana en el escritorio del host, detectado solo por `make run`, backend local en `10.0.2.2:9008` y estado conservado entre arranques. Comandos `emulator-build`, `emulator-up`, `emulator-down`, `emulator-logs` y `emulator-reset`.
- Login contra la API con `device_name` automático (p. ej. «Google Pixel 7 (Android 16)»), errores del backend bajo el formulario y, ante el `429`, cuenta atrás con el botón desactivado hasta `Retry-After`. En debug muestra la URL del servidor.
- Sesión en el almacenamiento seguro del sistema (Keystore en Android, Keychain en iOS), con el backup automático de Android desactivado.
- Pantalla de carga al abrir la app mientras se valida la sesión con `/me`; sin red se entra con la sesión guardada y con el token revocado se vuelve al login.
- Menú ⋮ en el inicio con el usuario, el dispositivo y «Cerrar sesión» (con confirmación; revoca el token en el backend y borra la sesión aunque no haya red).
- Portada del Diario (`GET /api/v1/diario`): fecha de hoy, racha, audios de la semana, tema del mes, resumen del día plegable (con leyenda de emojis, temas y estado de la generación), filtro por estado y entradas con hora, duración, estado y transcripción («Ver más» en las largas).
- Recarga del Diario al deslizar, al volver a la app y, mientras haya un audio pendiente o un resumen en curso, cada 10 s con la app en primer plano y la pestaña visible. Si falla una recarga se mantienen los datos con un aviso.
- Barra de navegación inferior con Diario, Historial, Buscar y Más (las tres últimas, provisionales).
- Grabar notas de voz desde el Diario (botón 🎙): hoja inferior con tiempo, nivel de entrada, Pausa/Continuar, Descartar (con confirmación, también al pulsar atrás) y Enviar. AAC-LC `.m4a` en mono a 64 kbps, máximo de 45 min, pantalla encendida mientras graba y pausa al salir de la app.
- Subida de la nota (`POST /api/v1/audios`) con progreso, aviso según el resultado (nueva, ya subida o vuelta a transcribir) y recarga del Diario. Si falla, la hoja se queda abierta con «Reintentar» y «Descartar» (sin cola de subidas).
- Micrófono del PC en el emulador (socket de PulseAudio/PipeWire del host y `-allow-host-audio`).
- Escuchar las notas del Diario (botón ▶): se descargan enteras con el token a un fichero temporal, que se borra al acabar, al parar o al pasar a otra. Mientras descarga, el botón muestra el progreso y tocarlo cancela.
- Reproductor dentro de la tarjeta con barra de salto, tiempo y velocidad (1×, 1,5×, 2×). Un audio cada vez; grabar una nota pausa la que suena.
- Reproducción en segundo plano con controles en la notificación y en la pantalla de bloqueo («Nota del 15/10 05:02»), con `audio_service` y `just_audio`.
- Historial: calendario mensual de lunes a domingo con el nº de notas de cada día en una pastilla de color y un punto si hay resumen; cambio de mes con ‹/› o deslizando, y hoy marcado con un círculo.
- Pantalla de un día del historial con su resumen, filtro por estado y notas con ▶, y flechas para saltar al día con notas anterior o siguiente sin pasar por los vacíos (requiere un backend posterior a 0.19.0; con uno anterior salen desactivadas).
- App en español, también en los textos de Material y las fechas (`flutter_localizations`, `intl`).
- CI en GitHub Actions (formato, análisis y tests), hook `pre-commit` de formato y guardas de Claude Code (sin commits en `develop`/`main`, `dart format` al editar).

### Cambiado

- `make apk` para los demonios de Gradle y Kotlin al terminar: con ellos vivos el emulador se colgaba al arrancar.

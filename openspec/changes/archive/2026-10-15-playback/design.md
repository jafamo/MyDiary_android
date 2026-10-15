## Context

`GET /api/v1/audios/{id}/fichero` devuelve el fichero original con su `Content-Type` (`audio/ogg` en los de Telegram, `audio/mp4` en los de la app; también `audio/mpeg` y `audio/wav`). `404 not_found` si el audio o su fichero no existen.

`just_audio` añade cabeceras HTTP con un proxy local en `127.0.0.1` (exige HTTP en claro en release y excepciones de ATS) o con la API nativa (en iOS, no documentada). El usuario ha elegido evitarlo: **descargar el fichero con `ApiClient` y reproducir el local**, borrándolo al terminar.

Para sonar en segundo plano, `just_audio_background` está en beta y sin versiones desde hace 17 meses; se usa `audio_service` (0.18.19), del mismo autor, sobre el que está construido.

## Goals / Non-Goals

**Goals:**

- Escuchar una nota con un toque, con salto y velocidad.
- Seguir escuchando con la pantalla apagada o desde otra app.

**Non-Goals:**

- Caché de audios ya escuchados (se borran al terminar).
- Streaming con `Range` (se descarga entero; una nota de 45 min son unos 22 MB).
- Cola o lista de reproducción (un audio cada vez).
- Reproducir en Historial o Búsqueda: llegan en la fase 5 y reutilizarán el mismo reproductor.
- Audios Ogg/Opus en iOS (D4).

## Decisions

### Interfaz `Player`

Como `Recorder`: interfaz para probar sin dispositivo (`AGENTS.md`).

- `load(path, title)`, `play()`, `pause()`, `seek(position)`, `setSpeed(speed)`, `stop()`.
- Streams: estado (`playing`, `completed`), posición y duración.
- `ServicePlayer` la implementa con un `BaseAudioHandler` de `audio_service` que envuelve un `AudioPlayer` de `just_audio`: publica `mediaItem` (título y duración) y `playbackState` (controles reproducir/pausa y parar, acciones de salto) para la notificación y la pantalla de bloqueo. Los botones de la notificación llaman al mismo handler, así que la app ve los cambios por los mismos streams.
- `AudioService.init` va en `main()` antes de `runApp`. `playerProvider` expone el `Player`, y los tests lo sustituyen por un doble.

### Controlador

`PlaybackController` (`Notifier`, sin `autoDispose`: vive mientras la app, porque suena en segundo plano). Estado:

- `audioId` de la nota actual (o ninguna), `phase` (`downloading`, `playing`, `paused`), progreso de descarga, posición, duración y velocidad.

Funcionamiento:

- `toggle(audio)`: si es la actual, pausa o continúa. Si es otra, para la actual (y borra su fichero), descarga la nueva con `ApiClient.download` (con `CancelToken`, que se cancela si se pide otra) y la reproduce.
- Al acabar (`completed`) o con `stop()` (también desde la notificación): para, borra el fichero y vuelve a sin nota.
- `seek` y `cycleSpeed` (1× → 1,5× → 2× → 1×).
- Fallo de descarga: vuelve a sin nota y expone el error una vez para el aviso (`SnackBar`).
- Ficheros `escucha-<id>.<ext>` en el directorio temporal, con la extensión según el `Content-Type`. Antes de cada descarga se borran los que quedaran (p. ej. si se cerró la app sonando).
- Al empezar a grabar, `pause()`.

### `ApiClient.download`

`download(path, savePath, {onReceiveProgress, cancelToken})` con `Dio.download`: misma URL base, token y traducción de errores. Devuelve el `Content-Type`. Una cancelación no es un error que se muestre.

### Interfaz

- Botón ▶ (`IconButton`, tooltip «Escuchar») al principio de la fila de la hora. Descargando: indicador circular con el progreso (toque = cancelar). Sonando: ⏸ («Pausa»).
- Debajo, mientras es la nota actual: `Slider` (salto al soltar), `0:05 / 0:14` y la velocidad como botón de texto (`1×`).
- La tarjeta no se expande ni se mueve más que esa fila.

### Android e iOS

- `MainActivity : AudioServiceActivity()`.
- Manifest: `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`; servicio `com.ryanheise.audioservice.AudioService` (`foregroundServiceType="mediaPlayback"`) y receptor `MediaButtonReceiver`. Las notificaciones de sesión multimedia no necesitan `POST_NOTIFICATIONS`.
- `AudioServiceConfig`: `androidStopForegroundOnPause: true` (en pausa la notificación se puede quitar) con canal «Reproducción».
- iOS: `UIBackgroundModes` → `audio`.

## Risks / Trade-offs

- **Espera antes de oír:** se descarga entero. Las notas habituales son de segundos o pocos minutos; con la red de casa, inmediato.
- **Android 12+ y servicios en primer plano:** reanudar desde segundo plano tras una pausa larga puede fallar (`ForegroundServiceStartNotAllowedException`); en ese caso se reanuda desde la app. Se acepta.
- **Una sola instancia:** `AudioService.init` solo se puede llamar una vez; los tests no lo usan.

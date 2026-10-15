## Why

Fase 3 de `ROADMAP.md`. Hoy las notas de voz solo llegan por Telegram. El objetivo principal de la app es grabarlas y subirlas directamente, con `POST /api/v1/audios`.

## What Changes

- **Botón 🎙 flotante en el Diario.** Abre una hoja inferior que empieza a grabar al momento. La hoja muestra el tiempo, el nivel de entrada y los botones Pausa/Continuar, Descartar y Enviar.
- **Grabación AAC-LC en `.m4a`** (mono, 64 kbps, 44,1 kHz) con `record`, en un fichero temporal.
  - Se para sola a los 45 min, que son unos 22 MB, por debajo del máximo de 25 MB del backend.
  - Mientras graba, la pantalla no se apaga (`wakelock_plus`).
  - Si se sale de la app, la grabación se pausa y se conserva lo grabado.
- **Permiso del micrófono**: se pide al empezar. Si se deniega, la hoja lo explica y remite a los ajustes del sistema.
- **Subida multipart** con progreso. Según el `result`, la hoja se cierra con un aviso: `created` («Nota enviada»), `duplicate` («ya estaba subida») o `retrying` («se vuelve a transcribir»). Después el Diario se recarga, y el sondeo de la fase 2 sigue la transcripción.
- **D6, sin cola**: si la subida falla, la hoja sigue abierta con el error, «Reintentar» y «Descartar». Reintentar es seguro porque el backend es idempotente por contenido. Si se cierra la app, la grabación se pierde.
- **Descartar** pide confirmación y borra el fichero. Mientras se graba, la hoja no se cierra deslizando ni con «atrás» sin esa confirmación.
- La nota queda con la fecha de la subida (`received_at` lo pone el backend). Se acepta: casi siempre se sube al momento.
- **Emulador con micrófono**: usa el micrófono del PC (PulseAudio/PipeWire del host y `-allow-host-audio`), solo en desarrollo.

## Capabilities

### New Capabilities

- `recording`: grabar una nota de voz y subirla, con permisos, pausa, límite de duración, resultado de la subida y errores.

### Modified Capabilities

- `dev-environment`: el emulador de Android recibe el audio del micrófono del host.

## Impact

- Dependencias: `record` (verificado, cow-level.ovh), `path_provider` (flutter.dev) y `wakelock_plus` (fluttercommunity.dev).
- Android: permiso `RECORD_AUDIO`. iOS: `NSMicrophoneUsageDescription`.
- Código:
  - `lib/recording/`: interfaz `Recorder` con su implementación sobre `record` y `wakelock_plus`, modelo `AudioUpload`, controlador de la hoja y la propia hoja.
  - El botón en `diary_screen.dart`.
- Docker: servicio `emulator` con el socket de PulseAudio del host, sin `-no-audio` y con `-allow-host-audio`.
- `ROADMAP.md`: D6 decidida (sin cola).
- Sin cambios en el backend.

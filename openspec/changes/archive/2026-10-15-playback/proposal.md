## Why

Fase 4 de `ROADMAP.md`. La app ya muestra y graba notas, pero no deja escucharlas: solo se lee su transcripción. El backend sirve el fichero en `GET /api/v1/audios/{id}/fichero`, con el token.

## What Changes

- **Botón ▶ en cada entrada del Diario**, en la fila de la hora, en cualquier estado (el audio existe aunque la transcripción falle o siga en curso). Al pulsarlo, la app descarga el fichero y lo reproduce; mientras, el botón muestra el progreso.
- **Reproductor dentro de la tarjeta**: mientras suena o está en pausa, la tarjeta muestra la barra de progreso con salto, el tiempo (`0:05 / 0:14`) y la velocidad (1×, 1,5× o 2×). Solo suena un audio a la vez: ▶ en otro para el anterior.
- **Descargar y reproducir** (decisión del usuario): el fichero se baja entero con `ApiClient` (que ya lleva el token) a un temporal y se reproduce desde local. Se borra al terminar: al acabar el audio, al parar o al pasar a otro. Los que queden de una sesión anterior se borran al reproducir el siguiente.
- **Sigue sonando en segundo plano** (decisión del usuario), con la pantalla apagada o fuera de la app, con controles en la notificación y en la pantalla de bloqueo («Nota del 15/10 05:02»: reproducir/pausa, salto y parar). `audio_service` sobre `just_audio`.
- Grabar una nota pausa lo que esté sonando.
- Errores de la descarga con el `message` del backend (p. ej. `404` si el audio ya no existe) en un aviso.

## Capabilities

### New Capabilities

- `playback`: escuchar el audio de una entrada, con descarga, controles, velocidad, reproducción en segundo plano y limpieza del fichero.

### Modified Capabilities

Ninguna.

## Impact

- Dependencias: `just_audio` y `audio_service` (ryanheise.com, verificado).
- Android: `MainActivity` extiende `AudioServiceActivity`; permisos `WAKE_LOCK`, `FOREGROUND_SERVICE` y `FOREGROUND_SERVICE_MEDIA_PLAYBACK`; servicio `AudioService` (`mediaPlayback`) y receptor `MediaButtonReceiver`. iOS: `UIBackgroundModes` con `audio`.
- Código: `ApiClient.download`, `lib/playback/` (interfaz `Player` con la implementación sobre `audio_service` + `just_audio`, controlador) y el reproductor en la tarjeta de `diary_screen.dart`. `main.dart` inicia `AudioService` antes de `runApp`.
- `Makefile`: `make apk` para los demonios de Gradle y Kotlin al terminar; con ellos vivos (unos 3 GB) el emulador se colgaba al arrancar. Anotado en `AGENTS.md`.
- Sin cambios en el backend. Los audios Ogg/Opus de Telegram siguen sin reproducirse en iOS (D4, fase 8).

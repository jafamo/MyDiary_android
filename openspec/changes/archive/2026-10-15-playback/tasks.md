## 1. Dependencias y plataforma

- [x] 1.1 `just_audio` y `audio_service`
- [x] 1.2 Android: `MainActivity : AudioServiceActivity`, permisos, servicio y receptor. iOS: `UIBackgroundModes` `audio`

## 2. Descarga

- [x] 2.1 `ApiClient.download` con progreso, cancelación y errores, con tests

## 3. Reproducción

- [x] 3.1 Interfaz `Player` y `ServicePlayer` (`BaseAudioHandler` + `just_audio`), `AudioService.init` en `main()`, `playerProvider`
- [x] 3.2 `PlaybackController`: descargar, reproducir, pausar, cambiar de nota, salto, velocidad, fin, parar, errores y limpieza de ficheros
- [x] 3.3 Pausar al grabar

## 4. Interfaz

- [x] 4.1 Botón ▶/⏸ con progreso de descarga y fila del reproductor en la tarjeta del Diario
- [x] 4.2 Tests de widget con un `Player` falso y el backend falso

## 5. Verificación

- [x] 5.1 `make format-check`, `make analyze`, `make test`
- [x] 5.2 En el emulador (verificado por el usuario): escuchar una nota de la app, salto, velocidad, pausa, salir de la app sonando y controles de la notificación. Sin audios de Telegram en el Diario de hoy: el Ogg se probará en la fase 5 (Historial)

## 6. Cierre

- [x] 6.0 `make apk` para los demonios de Gradle y Kotlin al terminar (colgaban el emulador al arrancarlo) y `AGENTS.md`

- [x] 6.1 `ROADMAP.md` (fase 4) y `CHANGELOG.md`
- [x] 6.2 Validar, archivar, commit, `git flow feature finish` y push de `develop`

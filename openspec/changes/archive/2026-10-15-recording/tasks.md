## 1. Dependencias y plataforma

- [x] 1.1 `record`, `path_provider` y `wakelock_plus`
- [x] 1.2 `RECORD_AUDIO` en Android y `NSMicrophoneUsageDescription` en iOS

## 2. Datos y subida

- [x] 2.1 Modelo `AudioUpload` (`UploadResult`) con fixtures y tests
- [x] 2.2 `onSendProgress` en `ApiClient.post` con test

## 3. Grabación

- [x] 3.1 Interfaz `Recorder` y `RecordRecorder` (`record` + `wakelock_plus`), `recorderProvider`
- [x] 3.2 `RecordingController`: permiso, tiempo, niveles, pausa, máximo de 45 min, envío con progreso, error y reintento, descartar y limpieza de ficheros
- [x] 3.3 Tests del controlador con un `Recorder` falso y el backend falso

## 4. Interfaz

- [x] 4.1 Hoja de grabación (estados, barras de nivel, confirmación al descartar y al pulsar atrás, pausa al salir de la app)
- [x] 4.2 Botón «Grabar nota» en el Diario, aviso según `result` y recarga
- [x] 4.3 Tests de widget: grabar y enviar, duplicado, sin permiso, error y reintento, descartar, atrás

## 5. Emulador

- [x] 5.1 Socket de PulseAudio del host, `-allow-host-audio` y `libpulse0` si hace falta

## 6. Verificación

- [x] 6.1 `make format-check`, `make analyze`, `make test`
- [x] 6.2 En el emulador: grabar con el micrófono del PC y enviar; la nota aparece en el Diario (audio con `source app`). La transcripción falló en el backend local por la clave de Open WebUI (`401`), no por la app, y el Diario mostró el error

## 7. Cierre

- [x] 7.1 `AGENTS.md` (micrófono del emulador), `ROADMAP.md` (fase 3 y D6) y `CHANGELOG.md`
- [x] 7.2 Validar, archivar, commit, `git flow feature finish` y push de `develop`

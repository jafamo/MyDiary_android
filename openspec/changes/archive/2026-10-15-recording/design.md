## Context

`POST /api/v1/audios` recibe el fichero en el campo `file` (m4a, mp3, ogg o wav, máximo 25 MB). Responde con un Audio breve más `result`:

- `201` con `created`.
- `200` con `duplicate` (mismo SHA-256) o `retrying` (existía en `ERROR` y se relanza).

La duración la calcula el servidor, y `received_at` es el momento de la subida.

`record` no graba en segundo plano: su documentación remite a `flutter_foreground_task`. Sin un servicio en primer plano, Android corta el micrófono cuando la app deja de estar visible.

Decisiones del usuario:

- Sin cola de subidas.
- Se acepta la fecha de subida.
- Solo se graba con la app abierta.
- La grabación va en una hoja inferior.

## Goals / Non-Goals

**Goals:**

- Grabar y enviar una nota en dos toques: 🎙 y Enviar.
- No perder la grabación por un fallo de red mientras la app siga abierta.

**Non-Goals:**

- Cola persistente o subida en segundo plano (D6: descartada por ahora).
- Grabar con la pantalla bloqueada o fuera de la app.
- Escuchar la nota antes de enviarla (la reproducción llega en la fase 4).
- Subir ficheros de audio existentes desde el móvil.
- Enviar la hora de grabación (el backend no la admite).

## Decisions

### Interfaz `Recorder`

Es la interfaz que `AGENTS.md` prevé para poder probar sin dispositivo.

- Métodos: `hasPermission()`, `start(path)`, `pause()`, `resume()`, `stop()` → ruta, `cancel()` y `amplitude` (stream en dBFS).
- `RecordRecorder` la implementa sobre `AudioRecorder` de `record` y activa y desactiva `wakelock_plus` al empezar y al terminar. Así el wakelock no aparece en los tests.
- Configuración: `AudioEncoder.aacLc`, `bitRate: 64000`, `sampleRate: 44100`, `numChannels: 1`. Calidad sobrada para voz y para Whisper: unos 0,48 MB/min.
- `recorderProvider` la expone y los tests la sustituyen por un doble.

### Controlador de la grabación

`RecordingController` (`Notifier` con `autoDispose`) con un estado inmutable `RecordingState`:

- `phase`: `starting`, `noPermission`, `recording`, `paused`, `uploading`, `failed`.
- `elapsed`, los últimos niveles para las barras, el progreso de subida y el error.

Funcionamiento:

- El tiempo se cuenta con un `Timer` de 1 s mientras está en `recording`, y en pausa no avanza.
- A los 45 min (`maxDuration`) se pausa sola y avisa «Has llegado al máximo de 45 min.». Solo se puede enviar o descartar.
- `send()` para la grabación y sube con `ApiClient.post` y `FormData`: `MultipartFile.fromFile(path, filename: 'nota.m4a')`, con `onSendProgress`.
  - Si sale bien, borra el fichero y devuelve el `AudioUpload`.
  - Si falla, pasa a `failed` con el `message` de la `ApiException` y conserva el fichero. `retry()` vuelve a subir el mismo fichero.
- `discard()` cancela la grabación y borra el fichero.
- Enviar se desactiva por debajo de 1 s, para que un toque accidental no suba un fichero vacío que el backend rechazaría con `422`.
- El fichero va en el directorio temporal (`path_provider`) con nombre por fecha (`nota-<epoch>.m4a`). Al empezar se borran las notas que hayan quedado de una sesión anterior: sin cola, no tienen uso.

`ApiClient.post` necesita `onSendProgress`. Se añade como parámetro opcional.

### Ciclo de vida

Un `AppLifecycleListener` en la hoja pausa la grabación en `onHide`. Al volver, sigue en pausa y el usuario decide si continuar. No se reanuda sola, porque el usuario puede no estar listo para hablar.

### Hoja (`RecordingSheet`)

`showModalBottomSheet` con `isDismissible: false` y `enableDrag: false`. Un `PopScope` intercepta «atrás»: si hay algo grabado, pide confirmación («¿Descartar la nota?»).

- **Grabando / en pausa**: punto rojo y «Grabando» o «En pausa», el tiempo `mm:ss` y barras con los últimos ~40 niveles. Botones Descartar, Pausa/Continuar y Enviar.
- **Enviando**: barra de progreso y «Enviando…», sin botones.
- **Error**: el mensaje, con Reintentar y Descartar.
- **Sin permiso**: «MyDiary necesita el micrófono para grabar. Actívalo en los ajustes del sistema.» y Cerrar.

Al terminar la subida, la hoja se cierra con el `AudioUpload`. El Diario muestra un `SnackBar` según `result` e invalida `diaryProvider`:

- `created`: «Nota enviada. Se está transcribiendo.»
- `duplicate`: «Esta nota ya estaba subida.»
- `retrying`: «Esta nota ya estaba subida. Se vuelve a transcribir.»

### Botón

`FloatingActionButton` 🎙 en el `Scaffold` del Diario, con el tooltip «Grabar nota».

### Modelo

`AudioUpload` en `lib/models/audio_upload.dart`, con el `Audio` breve (reutiliza `Audio.fromJson`) y `result` (`UploadResult`: `created`, `duplicate`, `retrying` o `unknown`).

### Plataformas

- Android: `RECORD_AUDIO` en el manifest principal.
- iOS: `NSMicrophoneUsageDescription` («MyDiary usa el micrófono para grabar tus notas de voz.»). Nada de `UIBackgroundModes`.

### Emulador con micrófono

El servicio `emulator` monta el socket de PulseAudio del host (`${XDG_RUNTIME_DIR}/pulse/native`, que con PipeWire lo da `pipewire-pulse`) y define `PULSE_SERVER`. El emulador arranca sin `-no-audio` y con `-allow-host-audio`. Si la imagen necesita `libpulse0`, se añade al `Dockerfile` del emulador.

## Risks / Trade-offs

- **Sin cola, si se cierra la app con una subida fallida, la nota se pierde.** Lo ha elegido el usuario. La hoja lo deja claro al no cerrarse sin confirmar.
- **Pausa al salir de la app.** Una llamada entrante también pausa la grabación. Es el comportamiento esperado.
- **Ruido del micrófono del host** en el emulador: solo afecta al desarrollo.
- **iOS sin probar** hasta la fase 8. `record` y `path_provider` lo soportan, y el permiso queda declarado.

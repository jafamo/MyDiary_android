# AGENTS.md

Instrucciones para trabajar en este repositorio (MyDiary app — cliente móvil Flutter de la API de MyDiary).

## Qué es este proyecto

App móvil (Android primero, iPhone después, **mismo código**) que da acceso a MyDiary: consultar el diario, historial, resúmenes, búsqueda, recordatorios, estadísticas y temas, y **grabar y subir notas de voz sin pasar por Telegram**.

- **No hay lógica de negocio en la app.** Transcripción, resúmenes, búsqueda semántica, rachas y estadísticas los calcula el backend; la app pide, muestra y edita.
- **Un solo usuario**, el mismo que en la web. Sin registro ni recuperación de contraseña: los usuarios se gestionan por consola en el servidor.

## Fuentes de verdad

- **Backend:** repositorio Symfony en `/home/jfarinos/Projects/MyDiary` (GitHub `jafamo/MyDiary`). Este repo **no lo modifica**; si la app necesita algo nuevo de la API, se propone allí con su propio flujo (OpenSpec + Git Flow de ese repo) y aquí solo se consume.
- **Contrato de la API:** `/home/jfarinos/Projects/MyDiary/doc/openapi.json` es la referencia exacta (esquemas, códigos de respuesta). Resumen orientado a la app en [`doc/BACKEND.md`](doc/BACKEND.md); si discrepan, manda `openapi.json` y hay que actualizar `doc/BACKEND.md`.
- **Dominio del backend:** `/home/jfarinos/Projects/MyDiary/Especificaciones.md` (sección 3.7 = API) y `ROADMAP.md` de ese repo (fases de la API pensadas para la app).
- **Plan de la app:** [`ROADMAP.md`](ROADMAP.md) de este repo.

Antes de implementar una pantalla o llamada nueva, comprobar el endpoint en `openapi.json` (no inventar campos ni deducirlos de la web).

## Stack

| | Componente | Tecnología |
|---|---|---|
| 🎯 | Plataformas | Android (primero) e iOS (después), un único código |
| 🐦 | Framework / lenguaje | Flutter (canal stable) / Dart |
| 🎙️ | Grabación | `record` — AAC-LC en `.m4a` en las dos plataformas |
| 🔊 | Reproducción | `just_audio` (ExoPlayer en Android, AVPlayer en iOS) con cabecera `Authorization` y `Range` |
| 🌐 | HTTP | `dio` (multipart para la subida de audio) |
| 🔑 | Token | `flutter_secure_storage` (Keystore en Android, Keychain en iOS) |
| 🔔 | Push (más adelante) | `firebase_messaging` (FCM para Android e iOS) — pendiente de decisión, ver `ROADMAP.md` |

Elección de Flutter frente a Kotlin Multiplatform y React Native razonada el 2026-10-14: los plugins cubren todo lo que necesita la app y la UI se comparte al 100%. Antes de añadir cualquier otro paquete, comprobar en pub.dev que esté mantenido (última versión, publisher verificado, plataformas) y justificarlo en la propuesta.

## Restricciones de arquitectura

Mismo espíritu que el backend: proyecto personal de un solo usuario, **introducir un patrón solo cuando el problema que resuelve ya existe**.

- **Sin Clean Architecture por capas** (data/domain/presentation por feature), sin casos de uso de una línea, sin repositorios abstractos con una sola implementación. Los modelos que devuelve la API SON el modelo de la app.
- **Un cliente de API único** (`ApiClient`) que añade el token, traduce el error `{code, message}` a una excepción tipada y conoce la URL base. Las pantallas no construyen peticiones HTTP a mano.
- **Una clase de modelo por esquema de `openapi.json`** (`Audio`, `Transcription`, `Summary`, `SummaryGeneration`, `Topic`, `Reminder`, `Statistics`...), con los nombres de campo de la API en `snake_case` mapeados explícitamente. Los modelos no se reescriben por pantalla.
- **Interfaces solo donde hay razón real** (p. ej. grabador/reproductor de audio para poder probar sin dispositivo). No generalizar.
- **Sin caché offline ni base de datos local** salvo que se pida. Tampoco cola de subidas: decidido en la fase 3 (D6 del `ROADMAP.md`), si la subida de una nota falla se reintenta desde la propia hoja de grabación.
- **Sin lógica de dominio duplicada**: nada de calcular rachas, estadísticas, calendarios agregados o estados en la app. Si falta un dato, se pide al backend.

**Opciones de diseño antes de implementar.** Si el cambio implica decisiones de diseño (gestión de estado, navegación, generación de código de modelos, dónde vive un servicio, estructura de carpetas), antes de tocar código proponer 2-3 alternativas con sus pros y contras y esperar a que el usuario elija. En la parte visual, lo equivalente es un mockup previo. Decisiones aún abiertas: ver `ROADMAP.md` (sección «Decisiones abiertas»).

## Convenciones con la API

Detalle en [`doc/BACKEND.md`](doc/BACKEND.md). Lo imprescindible:

- Prefijo `/api/v1`, JSON en `snake_case`, `Authorization: Bearer <token>` en todo salvo `POST /api/v1/login`.
- Instantes en ISO 8601 UTC (`2026-10-08T07:09:33Z`): se convierten a hora local **solo al mostrarlos**. Días (`AAAA-MM-DD`) son fechas de calendario en `Europe/Madrid`: **no convertir zona** (un `date` no es un instante).
- Errores siempre `{"code": "...", "message": "..."}`. Ramificar por `code` (estable), nunca por `message` (texto para humanos, se puede mostrar).
- `401` en cualquier petición = token caducado o revocado → borrar el token del almacenamiento seguro y volver al login.
- `429` en el login → respetar `Retry-After`.
- No guardar nunca el token fuera de `flutter_secure_storage`, ni loguearlo, ni la contraseña.

## Flujo de cambios (OBLIGATORIO)

Igual que en el backend. Todo cambio funcional, por pequeño que sea, sigue:

1. Crear y validar una propuesta OpenSpec (carpeta `openspec/`).
2. Crear una rama feature/bugfix con Git Flow.
3. Implementar con tests.
4. Añadir entrada en el CHANGELOG (`## [Sin publicar]`).
5. Sincronizar specs y archivar el cambio.
6. Hacer finish de la rama hacia `develop`.

Nunca implementar directamente sobre `develop`.

## Calidad y tests

- `flutter analyze` sin avisos y `dart format` aplicado antes de cada commit.
- `flutter test` debe pasar. Tests unitarios del `ApiClient` y del parseo de modelos contra respuestas reales (fixtures JSON sacadas de `openapi.json` o de una llamada real, sin datos personales); tests de widget en las pantallas con lógica de estado (p. ej. sondeo del resumen).
- Los tests no llaman a la API real ni dependen de un dispositivo: grabador, reproductor y cliente HTTP se sustituyen por dobles.
- La URL del backend y cualquier credencial **no se versionan**: se pasan con `--dart-define` / `--dart-define-from-file` (fichero ignorado por git). En el repo, solo un ejemplo (`env.example.json`).

## Entorno

- **Toolchain en Docker, nada instalado en el host.** Flutter (versión fijada en `docker/flutter/Dockerfile`, la misma que en `.github/workflows/ci.yml`), JDK 21 y SDK de Android viven en la imagen `mydiary-flutter`. El contenedor `mydiary-flutter` queda vivo (`make up`), usa la red del host y ejecuta como el usuario del host. Todos los comandos van por `make`: `get`, `format`, `format-check`, `analyze`, `test`, `apk`, `run`, `devices`, `sh`, `doctor`. No ejecutar `flutter`/`dart` en el host (no existen). Si el contenedor no está levantado, decirlo en lugar de dar algo por verificado.
- **Al cambiar la versión de Flutter:** actualizarla en el `Dockerfile`, en `docker-compose.yml` (tag de la imagen) y en la CI, y luego `make build`.
- **Configuración de la app:** `env/<entorno>.json` (no versionado; copia de `env.example.json`), elegido con `ENV=` (por defecto `dev`). `API_BASE_URL` sin `/api/v1`.
- **Dónde se prueba la app:** el usuario solo tiene iPhone, y desde Linux no se puede compilar para iOS (requiere Xcode en macOS; ver fase 8 del `ROADMAP.md`). En el día a día se usa el **emulador de Android en Docker**, opcional y solo de desarrollo: `make emulator-build` (una vez), `make emulator-up` (abre la ventana en el escritorio y tarda 60-90 s en arrancar; esperar a que `make devices` liste `emulator-5554`), `make run`, y `make emulator-down` al terminar (reserva 2 GB de RAM). `make emulator-reset` borra su estado. `make up` no lo arranca y nada de producción ni de la CI depende de él. Desde el emulador, el backend local es `http://10.0.2.2:9008` (el valor de `env.example.json`). El micrófono del emulador es el del PC (socket de PulseAudio/PipeWire del host y `-allow-host-audio`): solo tiene acceso mientras está arrancado. **Con 4 núcleos no da para compilar y emular a la vez**: con el emulador arrancado, una compilación completa de Gradle lo cuelga y lo cierra. Compilar primero con `make apk` con el emulador parado (al terminar para los demonios de Gradle y Kotlin, que se quedan con unos 3 GB y cuelgan el emulador al arrancar) y después `make emulator-up` y `make run` (que ya solo recompila lo cambiado). Si Android avisa de «System UI isn't responding» al arrancar, pulsar *Wait*: es lentitud del emulador, no de la app.
- **Móvil Android físico** (si algún día hay uno): depuración inalámbrica (Android 11+). `make adb-pair ADDR=<ip>:<puerto>` (una vez, pide el código), `make adb-connect ADDR=<ip>:<puerto>` y `make run`. En ese caso `API_BASE_URL` es la IP de esta máquina en la LAN, no `localhost`.
- **Backend local:** `make up` en `/home/jfarinos/Projects/MyDiary`, API en `http://localhost:9008` (`http://10.0.2.2:9008` desde el emulador). HTTP en claro solo en el build de debug (`usesCleartextTraffic` en `android/app/src/debug/AndroidManifest.xml`; ATS de iOS se resuelve en su fase).
- **Hooks:** `git config core.hooksPath .githooks` (formato en `pre-commit`). En Claude Code, `.claude/settings.json` bloquea commits en `develop`/`main` y formatea el `.dart` editado.
- Producción: servidor `zeus`, publicado tras el proxy KeenDNS (URL en `APP_PUBLIC_URL` del backend; no se versiona aquí). Solo HTTPS.
- Si el backend local no está levantado, decirlo en lugar de dar algo por verificado.
- Probar las peticiones a mano con `doc/api.http` o la colección Postman del backend (`/home/jfarinos/Projects/MyDiary/doc/`).

## Control de versiones: Git Flow (regla fija)

Este repositorio usa **Git Flow** (prefijos por defecto). Nunca commitear directo a `main` ni a `develop`:

- `main` — solo releases. `develop` — rama de integración, base de todo trabajo nuevo.
- Funcionalidad nueva → `git flow feature start <nombre>`; al terminar, `git flow feature finish <nombre>`.
- Corrección sobre `develop` → `git flow bugfix start <nombre>`.
- Release → `git flow release start <version>` / `git flow release finish`. Fix urgente sobre lo publicado → `git flow hotfix start <nombre>`.
- **Push:** tras terminar una feature/bugfix, push **solo de `develop`** salvo que el usuario pida expresamente una release.

## Versiones, tags y releases (regla fija)

- **Versionado:** SemVer **sin prefijo `v`** (`0.3.0`). `release` sube minor (o major); `hotfix` sube patch. La versión de `pubspec.yaml` (`X.Y.Z+build`) se actualiza en la rama de release/hotfix, incrementando siempre el `build` (lo exigen Play Store y App Store).
- **CHANGELOG antes del finish:** mover `## [Sin publicar]` a `## [X.Y.Z] - AAAA-MM-DD` (dejando `## [Sin publicar]` vacío arriba), con secciones `Ramas integradas en develop`, `Añadido` / `Cambiado` / `Corregido` y, si aplica, `Requiere backend` (versión mínima del backend). Commit `Prepare release X.Y.Z`.
- **Tags siempre anotadas, mensaje `Release X.Y.Z`:** `GIT_MERGE_AUTOEDIT=no git flow release finish -m "Release" X.Y.Z` (el git-flow instalado añade la versión al final del mensaje; por eso solo `"Release"`). Igual con `hotfix finish`. Nunca tags ligeras.
- **Publicar:** `git push origin main develop --tags`.
- **No reescribir tags ya publicadas** salvo petición expresa.

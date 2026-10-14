## Why

Es la fase 0 de `ROADMAP.md`: antes de la primera pantalla útil (login, fase 1) hace falta un proyecto Flutter que compile, un entorno reproducible para construirlo y la pieza que usarán todas las fases: el cliente de la API de MyDiary con sus modelos. En esta máquina no hay Flutter ni SDK de Android, y el Java del sistema (27) no lo admite Gradle; el usuario prefiere no instalar el toolchain en el host.

## What Changes

- **Toolchain en Docker**: imagen con Flutter 3.47.7 (stable), JDK 21 y SDK de Android, que ejecuta como el usuario del host para que los ficheros generados no sean de `root`. Contenedor de larga duración `mydiary-flutter` (red del host, para llegar al backend local y a un móvil por depuración inalámbrica) y `Makefile` con los comandos habituales (`make up`, `make test`, `make analyze`, `make apk`, `make run`...), como en el backend.
- **Proyecto Flutter** para Android e iOS (`flutter create`), con `applicationId` / bundle id `com.jfarinos.mydiary`, permiso de Internet y HTTP en claro solo en el build de debug.
- **Configuración por `--dart-define-from-file`**: URL del backend en `env/<entorno>.json` (ignorado por git); en el repo, solo `env.example.json`. Sin URL configurada la app no arranca.
- **Decisiones D1–D3 del roadmap**, ya elegidas por el usuario: Riverpod sin generación de código, `go_router`, y modelos con `fromJson` escritos a mano.
- **`ApiClient` único** sobre `dio`: URL base `/api/v1`, cabecera `Authorization: Bearer`, traducción de todo error a `ApiException` con `code` estable (los del backend más `network_error` e `invalid_response` del lado cliente), aviso de sesión caducada ante un `401` y `Retry-After` en el `429`.
- **Modelos de los recursos** de `openapi.json`: `Audio`, `Transcription`, `Summary`, `SummaryGeneration`, `Topic`, `Reminder` y la página genérica `Paginated<T>`, con instantes en UTC y días como fechas de calendario sin zona. Las respuestas propias de un endpoint (diario, historial, estadísticas, búsqueda, login) se modelan en la fase que las usa.
- **Esqueleto de navegación**: rutas `/login` y `/` con pantallas provisionales y redirección según haya o no token (en memoria; el almacenamiento seguro llega en la fase 1).
- **Calidad**: `analysis_options.yaml` con análisis estricto de tipos, `dart format`, tests unitarios del cliente y los modelos y test de widget de la redirección. CI en GitHub Actions (formato, análisis y tests) y hook `pre-commit` de formato.
- **Guardas de Claude Code** como en el backend: bloquear `git commit` en `develop`/`main` y formatear los `.dart` editados.

## Capabilities

### New Capabilities

- `dev-environment`: toolchain en Docker, comandos de `make`, configuración por entorno, CI y hooks.
- `api-client`: cliente HTTP de `/api/v1`, formato de errores, tratamiento de `401` y `429`, y modelos de los recursos con sus reglas de fechas.
- `app-shell`: arranque de la app, configuración obligatoria y navegación con redirección al login.

### Modified Capabilities

(ninguna: es el primer cambio del repositorio)

## Impact

- Ficheros nuevos: `docker/flutter/Dockerfile`, `docker-compose.yml`, `Makefile`, proyecto Flutter (`lib/`, `test/`, `android/`, `ios/`, `pubspec.yaml`, `analysis_options.yaml`), `env.example.json`, `.github/workflows/ci.yml`, `.githooks/pre-commit`, `.claude/settings.json` y su hook.
- Dependencias: `dio`, `flutter_riverpod`, `go_router`.
- Documentación: `AGENTS.md` (entorno Docker y comandos), `ROADMAP.md` (fase 0 hecha, D1–D3 decididas), `CHANGELOG.md`.
- Sin cambios en el backend.
- Ejecutar la app en un móvil desde el contenedor requiere depuración inalámbrica (Android 11+). El emulador queda fuera de esta fase.

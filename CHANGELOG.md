# Changelog

Todos los cambios relevantes de la app se documentan aquí. Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y versionado [SemVer](https://semver.org/lang/es/) sin prefijo `v`.

## [Sin publicar]

### Ramas integradas en develop

- `feature/project-skeleton` — fase 0 del roadmap.
- `feature/android-emulator` — emulador de Android opcional en Docker.

### Añadido

- `AGENTS.md`, `CLAUDE.md`, `ROADMAP.md` y `doc/BACKEND.md` con el contexto del backend MyDiary y las reglas del repositorio.
- Toolchain en Docker (Flutter 3.47.7, JDK 21, SDK de Android): imagen `mydiary-flutter`, contenedor de larga duración con la red del host y `Makefile` (`build`, `up`, `get`, `format`, `format-check`, `analyze`, `test`, `apk`, `run`, `adb-pair`, `adb-connect`...).
- Proyecto Flutter para Android e iOS (`com.jfarinos.mydiary`), con HTTP en claro solo en el build de debug.
- Configuración por `--dart-define-from-file` (`env/<entorno>.json`, no versionado; ejemplo en `env.example.json`). Sin `API_BASE_URL` válida, la app muestra un error de configuración.
- `ApiClient` sobre `dio`: `/api/v1`, `Authorization: Bearer`, errores como `ApiException` con `code` estable (`network_error` e `invalid_response` del lado cliente), aviso de sesión caducada ante un `401` (salvo en el login) y `Retry-After` en el `429`.
- Modelos `Audio`, `Transcription`, `Summary`, `SummaryGeneration`, `Topic`, `Reminder` y `Paginated`, con instantes en UTC y días de calendario sin zona horaria.
- Navegación con `go_router` y estado con Riverpod: rutas `/login` e inicio (provisionales) con redirección según el token.
- Emulador de Android 36 en Docker, opcional y solo de desarrollo (perfil `emulator`, no lo arranca `make up`): ventana en el escritorio del host, detectado solo por `make run`, backend local en `10.0.2.2:9008` y estado conservado entre arranques. Comandos `emulator-build`, `emulator-up`, `emulator-down`, `emulator-logs` y `emulator-reset`.
- CI en GitHub Actions (formato, análisis y tests), hook `pre-commit` de formato y guardas de Claude Code (sin commits en `develop`/`main`, `dart format` al editar).

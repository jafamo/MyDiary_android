# Changelog

Todos los cambios relevantes de la app se documentan aquí. Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y versionado [SemVer](https://semver.org/lang/es/) sin prefijo `v`.

## [Sin publicar]

### Ramas integradas en develop

- `feature/project-skeleton` — fase 0 del roadmap.
- `feature/android-emulator` — emulador de Android opcional en Docker.
- `feature/login` — fase 1 del roadmap.

### Añadido

- `AGENTS.md`, `CLAUDE.md`, `ROADMAP.md` y `doc/BACKEND.md` con el contexto del backend MyDiary y las reglas del repositorio.
- Toolchain en Docker (Flutter 3.47.7, JDK 21, SDK de Android): imagen `mydiary-flutter`, contenedor de larga duración con la red del host y `Makefile` (`build`, `up`, `get`, `format`, `format-check`, `analyze`, `test`, `apk`, `run`, `adb-pair`, `adb-connect`...).
- Proyecto Flutter para Android e iOS (`com.jfarinos.mydiary`), con HTTP en claro solo en el build de debug.
- Configuración por `--dart-define-from-file` (`env/<entorno>.json`, no versionado; ejemplo en `env.example.json`). Sin `API_BASE_URL` válida, la app muestra un error de configuración.
- `ApiClient` sobre `dio`: `/api/v1`, `Authorization: Bearer`, errores como `ApiException` con `code` estable (`network_error` e `invalid_response` del lado cliente), aviso de sesión caducada ante un `401` (salvo en el login) y `Retry-After` en el `429`.
- Modelos `Audio`, `Transcription`, `Summary`, `SummaryGeneration`, `Topic`, `Reminder` y `Paginated`, con instantes en UTC y días de calendario sin zona horaria.
- Navegación con `go_router` y estado con Riverpod: rutas `/splash`, `/login` e inicio con redirección según la sesión.
- Emulador de Android 36 en Docker, opcional y solo de desarrollo (perfil `emulator`, no lo arranca `make up`): ventana en el escritorio del host, detectado solo por `make run`, backend local en `10.0.2.2:9008` y estado conservado entre arranques. Comandos `emulator-build`, `emulator-up`, `emulator-down`, `emulator-logs` y `emulator-reset`.
- Login contra la API con `device_name` automático (p. ej. «Google Pixel 7 (Android 16)»), errores del backend bajo el formulario y, ante el `429`, cuenta atrás con el botón desactivado hasta `Retry-After`. En debug muestra la URL del servidor.
- Sesión en el almacenamiento seguro del sistema (Keystore en Android, Keychain en iOS), con el backup automático de Android desactivado.
- Pantalla de carga al abrir la app mientras se valida la sesión con `/me`; sin red se entra con la sesión guardada y con el token revocado se vuelve al login.
- Menú ⋮ en el inicio con el usuario, el dispositivo y «Cerrar sesión» (con confirmación; revoca el token en el backend y borra la sesión aunque no haya red).
- CI en GitHub Actions (formato, análisis y tests), hook `pre-commit` de formato y guardas de Claude Code (sin commits en `develop`/`main`, `dart format` al editar).

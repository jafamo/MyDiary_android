## 1. Toolchain en Docker

- [x] 1.1 `docker/flutter/Dockerfile`: JDK 21, SDK de Android, Flutter 3.47.7, usuario con UID/GID del host y calentamiento con un APK desechable
- [x] 1.2 `docker-compose.yml` (servicio `flutter`, contenedor `mydiary-flutter`, red del host, volúmenes de caché de pub y Gradle)
- [x] 1.3 `Makefile` con `build`, `up`, `down`, `sh`, `get`, `format`, `format-check`, `analyze`, `test`, `apk`, `run`, `adb-pair`, `adb-connect`, y aviso si el contenedor no está levantado
- [x] 1.4 Construir la imagen y comprobar `flutter doctor` dentro del contenedor

## 2. Proyecto Flutter

- [x] 2.1 `flutter create` (Android + iOS, `com.jfarinos.mydiary`, proyecto `mydiary`) y limpiar el contador de ejemplo
- [x] 2.2 `.gitignore` con `env/*.json`, y `env.example.json`
- [x] 2.3 Permiso de Internet en el manifest principal y `usesCleartextTraffic` solo en el de debug
- [x] 2.4 Dependencias `dio`, `flutter_riverpod`, `go_router` y `analysis_options.yaml` estricto

## 3. Cliente de la API

- [x] 3.1 `AppConfig` desde `API_BASE_URL`, con validación
- [x] 3.2 `ApiException` y tabla de códigos por estado
- [x] 3.3 `ApiClient` (verbos, Bearer, traducción de errores, `401` salvo login, `Retry-After`, `invalid_response`)
- [x] 3.4 Tests del `ApiClient` con un adaptador HTTP falso: cabeceras, errores del backend, error sin formato, sin red, `401` con y sin aviso, `429`, respuesta inválida

## 4. Modelos

- [x] 4.1 Utilidades de JSON (instantes UTC, días de calendario, enteros y textos opcionales)
- [x] 4.2 `Audio`, `Transcription`, `Summary`, `SummaryGeneration`, `Topic`, `Reminder` y `Paginated<T>`, con enums con `unknown`
- [x] 4.3 Fixtures JSON según `openapi.json` y tests de parseo (incluye día sin zona, estado desconocido, campos `null`)

## 5. Arranque y navegación

- [x] 5.1 `authTokenProvider`, `apiClientProvider` y `routerProvider` con redirección
- [x] 5.2 Pantallas provisionales de login e inicio y pantalla de error de configuración
- [x] 5.3 Tests de widget: sin token → login, con token → inicio, token borrado → login; sin configuración → error

## 6. Calidad, CI y hooks

- [x] 6.1 `.github/workflows/ci.yml` (formato, análisis y tests)
- [x] 6.2 `.githooks/pre-commit` (formato con el contenedor) y `git config core.hooksPath .githooks`
- [x] 6.3 `.claude/settings.json`: guarda de commit en `develop`/`main` y formateo del `.dart` editado
- [x] 6.4 `make format-check`, `make analyze`, `make test` y `make apk` pasan

## 7. Documentación y cierre

- [x] 7.1 `AGENTS.md` (entorno Docker y comandos), `ROADMAP.md` (fase 0 hecha, D1–D3 decididas) y `CHANGELOG.md`
- [x] 7.2 `openspec validate`, sincronizar specs y archivar el cambio
- [x] 7.3 Commit en la rama y `git flow feature finish project-skeleton`

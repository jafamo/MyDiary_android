# dev-environment Specification

## Purpose
Entorno de desarrollo: toolchain en Docker, comandos de make, configuración por entorno, integración continua y guardas de commit.
## Requirements
### Requirement: Toolchain en Docker
El repositorio SHALL incluir una imagen Docker con Flutter (versión fijada), JDK 21 y el SDK de Android, suficiente para obtener dependencias, analizar, formatear, ejecutar los tests y construir un APK de Android sin instalar nada en el host salvo Docker. El contenedor SHALL ejecutarse con el UID/GID del usuario del host, y los ficheros que genere en el proyecto MUST NOT ser de `root`.

#### Scenario: Tests en una máquina solo con Docker
- **WHEN** en una máquina con Docker y sin Flutter se ejecuta `make build`, `make up` y `make test`
- **THEN** se ejecuta `flutter test` dentro del contenedor y termina con éxito

#### Scenario: Ficheros generados con el dueño correcto
- **WHEN** se ejecuta `make get` dentro del contenedor
- **THEN** `.dart_tool/` y `pubspec.lock` pertenecen al usuario del host

#### Scenario: APK de debug
- **WHEN** se ejecuta `make apk`
- **THEN** se genera `build/app/outputs/flutter-apk/app-debug.apk`

### Requirement: Comandos de make
El `Makefile` SHALL ofrecer al menos `build`, `up`, `down`, `sh`, `get`, `format`, `format-check`, `analyze`, `test`, `apk`, `run`, `adb-pair` y `adb-connect`, todos ejecutados dentro del contenedor. Si el contenedor no está levantado, los comandos SHALL fallar con un mensaje que indique ejecutar `make up`.

#### Scenario: Contenedor parado
- **WHEN** se ejecuta `make test` sin haber hecho `make up`
- **THEN** el comando falla con un mensaje que pide ejecutar `make up`

### Requirement: Configuración por entorno fuera del repositorio
La URL del backend SHALL pasarse a la app con `--dart-define-from-file` desde `env/<entorno>.json`. Los ficheros de `env/` MUST NOT versionarse, y el repositorio SHALL incluir `env.example.json` con todas las claves.

#### Scenario: Fichero de entorno ignorado
- **WHEN** existe `env/dev.json` y se ejecuta `git status`
- **THEN** `env/dev.json` no aparece como fichero sin seguimiento

### Requirement: Integración continua
Cada push y cada pull request SHALL ejecutar en GitHub Actions la comprobación de formato (`dart format --set-exit-if-changed`), `flutter analyze` y `flutter test`, con la misma versión de Flutter que la imagen Docker.

#### Scenario: Código sin formatear
- **WHEN** se sube un `.dart` que `dart format` cambiaría
- **THEN** el job de CI falla

### Requirement: Guardas de commit
El repositorio SHALL incluir un hook `pre-commit` (`.githooks/`) que compruebe el formato de los `.dart` en stage usando el contenedor, y que solo avise sin bloquear si el contenedor no está levantado. La configuración de Claude Code SHALL impedir `git commit` en `develop` y `main`.

#### Scenario: Commit con formato incorrecto
- **WHEN** con el contenedor levantado se intenta commitear un `.dart` sin formatear
- **THEN** el commit se rechaza indicando `make format`

### Requirement: Emulador de Android opcional
El repositorio SHALL ofrecer un emulador de Android en Docker para desarrollo, en un servicio de un perfil aparte que `make build` y `make up` MUST NOT construir ni arrancar. `make emulator-up` SHALL arrancarlo con la ventana en el escritorio del host. Con el emulador arrancado, `make run` SHALL ejecutar la app en él sin configurar nada más, y la app SHALL llegar al backend local a través de `http://10.0.2.2:9008`. El estado del emulador (app instalada y sus datos) SHALL conservarse entre arranques hasta que se reinicie explícitamente.

#### Scenario: Arranque normal sin emulador
- **WHEN** se ejecuta `make up`
- **THEN** solo arranca el contenedor `mydiary-flutter`, sin el emulador

#### Scenario: Emulador visible para adb
- **WHEN** se ejecuta `make emulator-up` y Android termina de arrancar
- **THEN** `make devices` lista `emulator-5554` como dispositivo

#### Scenario: Ejecutar la app en el emulador
- **WHEN** con el emulador arrancado se ejecuta `make run`
- **THEN** la app se instala y se abre en el emulador

#### Scenario: Estado conservado
- **WHEN** se para el emulador con `make emulator-down` y se vuelve a arrancar
- **THEN** la app sigue instalada


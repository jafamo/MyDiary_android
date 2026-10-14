## Why

El usuario solo tiene iPhone, y desde Linux no se puede compilar ni instalar una app de iOS (requiere Xcode en macOS). Sin un Android físico, hoy no hay dónde ejecutar la app durante el desarrollo. El emulador solo se usa para desarrollar: no debe arrancar con `make up` ni ser necesario para construir o probar.

## What Changes

- **Emulador de Android en Docker, opcional**: imagen `mydiary-emulator` construida sobre `mydiary-flutter` (reutiliza su SDK), con el emulador, la imagen de sistema Android 36 (`google_apis`, x86_64) y un AVD `mydiary` ya creado.
- **Servicio `emulator`** en `docker-compose.yml` bajo el perfil `emulator`: no lo construye `make build` ni lo arranca `make up`. Usa `/dev/kvm`, la red del host y la ventana se muestra en el escritorio del host (X11/XWayland).
- **Comandos de make**: `emulator-build`, `emulator-up`, `emulator-down` y `emulator-logs`. Con el emulador arrancado, `make run` instala y ejecuta la app en él sin más configuración, y la app llega al backend local por `http://10.0.2.2:9008`.
- **Estado del emulador persistente** (app instalada, sesión) en un volumen, para no partir de cero en cada arranque.

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

- `dev-environment`: nuevo requisito de emulador opcional; los requisitos existentes no cambian.

## Impact

- Ficheros: `docker/emulator/Dockerfile`, `docker-compose.yml`, `Makefile`, `AGENTS.md`, `README.md`, `CHANGELOG.md`.
- Imagen adicional de unos 3-4 GB, solo si se construye.
- Recursos: el emulador reserva 2 GB de RAM y 2 núcleos mientras está arrancado.
- Sin cambios en la app ni en la CI.

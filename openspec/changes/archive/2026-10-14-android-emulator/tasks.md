## 1. Imagen y servicio

- [x] 1.1 `docker/emulator/Dockerfile` sobre `mydiary-flutter`: librerías del emulador, `emulator`, imagen de sistema Android 36 y AVD `mydiary`
- [x] 1.2 Servicio `emulator` con perfil `emulator`, `/dev/kvm`, red del host, X11 y volumen del AVD
- [x] 1.3 `Makefile`: `emulator-build`, `emulator-up`, `emulator-down`, `emulator-logs`, `emulator-reset`; `down` también para el emulador

## 2. Verificación

- [x] 2.1 `make up` no arranca el emulador
- [x] 2.2 `make emulator-up` muestra la ventana y `make devices` lista `emulator-5554`
- [x] 2.3 `make run` instala y abre la app en el emulador
- [x] 2.4 La app sigue instalada tras `make emulator-down` y `make emulator-up`

## 3. Documentación y cierre

- [x] 3.1 `AGENTS.md`, `README.md` y `CHANGELOG.md`
- [x] 3.2 Validar, sincronizar specs, archivar, commit y `git flow feature finish`

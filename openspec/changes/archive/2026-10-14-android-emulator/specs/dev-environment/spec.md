## ADDED Requirements

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

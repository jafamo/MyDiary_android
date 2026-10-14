## Context

El toolchain vive en el contenedor `mydiary-flutter` (red del host, servidor de `adb` dentro). El host tiene `/dev/kvm` accesible, 4 núcleos, 15 GB de RAM y escritorio KDE sobre Wayland con XWayland (`DISPLAY=:1`). El usuario quiere el emulador como pieza opcional de desarrollo.

## Goals / Non-Goals

**Goals:**

- Ejecutar la app en un Android emulado con `make emulator-up` + `make run`, sin instalar nada en el host.
- Que nada del emulador afecte a `make build`, `make up`, la CI ni el tamaño de la imagen principal.

**Non-Goals:**

- Micrófono del emulador (hace falta para grabar, fase 3): se resuelve en esa fase, pasando el audio del host (PipeWire/PulseAudio) al contenedor.
- Aceleración de GPU del host.
- Emulador de iOS (imposible fuera de macOS).

## Decisions

### Imagen propia sobre `mydiary-flutter`

`docker/emulator/Dockerfile` parte de `mydiary-flutter:<versión>` (`ARG BASE`), añade las librerías de sistema que pide el emulador (Qt/X11, NSS, audio), instala con `sdkmanager` `emulator` y `system-images;android-36;google_apis;x86_64`, y crea el AVD `mydiary` (perfil `pixel_7`, 2 GB de RAM, 2 núcleos, teclado del host activado).

- **Por qué heredar:** reutiliza el SDK, el usuario `builder` y su UID. Además mantiene la imagen principal intacta.
- **Android 36:** es la plataforma con la que ya compila el proyecto. `google_apis` en vez de `google_apis_playstore`, porque no hace falta Play Store.
- Alternativa descartada: meter el emulador en la imagen principal con un `ARG`. Mezcla lo opcional con lo necesario y obliga a reconstruir el toolchain.

### Servicio con perfil y red del host

Servicio `emulator` con `profiles: [emulator]` en el mismo `docker-compose.yml`, `network_mode: host` y `devices: /dev/kvm`. Con la red del host, el emulador abre sus puertos de consola y adb (5554/5555) en `localhost`. El servidor de `adb` del contenedor `mydiary-flutter`, que también usa la red del host, lo detecta solo como `emulator-5554`. Por eso no hace falta `adb connect`, y `make run` lo encuentra.

Dentro del emulador, `10.0.2.2` es el loopback del host, así que llega al backend local en `:9008`. Es el valor que ya trae `env.example.json`.

### Pantalla: ventana X11 en el escritorio del host

El contenedor monta `/tmp/.X11-unix` y el fichero `$XAUTHORITY` del host (de solo lectura) y recibe `DISPLAY`. Como ejecuta con el mismo UID, no hace falta `xhost`. La GPU es la emulada por software (`-gpu swiftshader_indirect`), que no depende de los drivers del host.

Alternativas descartadas: emulador sin ventana más `scrcpy` en el host (hay que instalar algo en el host), y noVNC en el navegador (otro servicio más y más latencia).

### Red: Wi-Fi sin netsim

Android 36 solo tiene red por Wi-Fi emulada, que por defecto pasa por `netsim`. Dentro del contenedor `netsim` se cae al arrancar ("Netsim Wifi … is gone"), y Android se queda sin IP con la Wi-Fi en "CONNECTING". Con `-feature -WiFiPacketStream` el emulador usa su punto de acceso interno: `wlan0` recibe `10.0.2.16` y `10.0.2.2` llega al backend del host. Descartado `-feature -VirtioWifi`: deja Android sin ninguna interfaz activa.

### Estado persistente

El directorio del AVD (`/home/builder/.android/avd`) es un volumen con nombre: la primera vez se rellena desde la imagen, y después conserva la app instalada y su estado. Para empezar de cero se borra el volumen (`make emulator-reset`). Si el emulador se cierra de golpe, en el volumen quedan ficheros `*.lock` que impiden el siguiente arranque ("Running multiple emulators with the same AVD"), así que se borran antes de cada arranque. El arranque usa `-no-snapshot-save` para no escribir una instantánea de varios GB en cada parada. Con `-no-boot-anim` se acorta algo el arranque.

### Comandos

`make emulator-build`, `emulator-up`, `emulator-down`, `emulator-logs` y `emulator-reset`. `make down` también para el emulador (`--profile emulator`), para que no quede uno huérfano consumiendo RAM.

## Risks / Trade-offs

- [El host va justo de RAM (unos 6 GB libres en uso normal)] → AVD limitado a 2 GB. Si va lento, cerrar otros servicios o bajar a 1,5 GB.
- [La GPU por software es más lenta que la real] → Suficiente para una app de formularios y listas. Si molesta, probar `/dev/dri` + `-gpu host` en otro cambio.
- [`XAUTHORITY` cambia en cada sesión del escritorio] → El `Makefile` pasa la ruta actual al arrancar. Tras reiniciar sesión, basta con `make emulator-up` de nuevo.
- [Arranque lento: unos 60-90 s hasta `sys.boot_completed`] → Hay que esperar a que `make devices` lo liste. Justo después de arrancar, el gestor de paquetes puede no estar listo y la primera instalación fallar: basta con repetir `make run`.
- [Primer frame lento en debug con GPU por software (unos 20 s)] → Solo en el arranque de la app; el hot reload después es inmediato.

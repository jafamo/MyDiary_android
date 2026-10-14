## Why

Fase 1 de `ROADMAP.md`. Sin login no se puede llamar a ningún endpoint de datos. Hoy el token solo existe en memoria y la pantalla de login es provisional, así que cada arranque partiría sin sesión.

## What Changes

- **Login real** contra `POST /api/v1/login`, con usuario y contraseña. El `device_name` se rellena solo con el modelo y sistema del dispositivo (p. ej. «Google Pixel 7 (Android 16)»), sin campo en el formulario.
- **Sesión persistente**: token, usuario y nombre del dispositivo en `flutter_secure_storage` (Keystore en Android, Keychain en iOS, solo en este dispositivo). Se desactiva el backup automático de Android, que rompe la clave de cifrado al restaurar.
- **Validación al arrancar**: con sesión guardada, pantalla de carga y `GET /api/v1/me`. Con `401` se borra la sesión y se va al login. Sin red se entra con la sesión guardada.
- **Errores del login** debajo del formulario con el mensaje del backend. En el `429`, cuenta atrás con `Retry-After` y botón desactivado hasta que termine.
- **Cerrar sesión** desde el menú ⋮ del inicio, que muestra usuario y dispositivo y pide confirmación. Llama a `POST /api/v1/logout` y borra la sesión local aunque falle la red.
- **Sesión caducada**: cualquier `401` fuera del login borra también la sesión guardada, no solo la de memoria.
- En debug, el login muestra el servidor configurado.

## Capabilities

### New Capabilities

- `auth`: login, persistencia de la sesión, validación al arrancar, cierre de sesión, sesión caducada y límite de intentos.

### Modified Capabilities

- `app-shell`: la navegación pasa a depender de la sesión, con un estado nuevo «comprobando sesión» (pantalla de carga) antes de decidir entre login e inicio.

## Impact

- Dependencias: `flutter_secure_storage`, `device_info_plus`.
- Código: `lib/auth/` (sesión, almacenamiento, nombre del dispositivo, modelos `LoginResult` y `Me`), `lib/screens/` (login, carga, inicio con menú), `router.dart`, `providers.dart` (`dioProvider` para los tests).
- Android: `android:allowBackup="false"`.
- Sin cambios en el backend.

## Context

La fase 0 dejó un `authTokenProvider` en memoria que lee el `ApiClient`, el `401` que lo borra y un router con dos estados (con o sin token). Decisiones del usuario para esta fase: `device_name` automático, validar con `/me` al arrancar (entrando sin validar si no hay red) y login sencillo con el cierre de sesión en el menú ⋮ del inicio.

## Goals / Non-Goals

**Goals:**

- Iniciar sesión, conservarla entre arranques y cerrarla.
- Que un token revocado o caducado devuelva al login desde cualquier pantalla y no se quede guardado.

**Non-Goals:**

- Pantalla de cuenta con fechas del token (creado, último uso, caducidad).
- Biometría para abrir la app.
- Gestión de varios usuarios o varias cuentas.

## Decisions

### Dos niveles de estado: token y sesión

- `authTokenProvider` (ya existe): token en memoria, síncrono. Lo lee el `ApiClient` en cada petición y lo borra el `401`. No cambia.
- `sessionProvider` (nuevo, `AsyncNotifier<Session?>`): `Session(token, username, deviceName)`. Su estado de carga es «comprobando sesión».
  - `build()`: lee el almacenamiento. Sin sesión → `null`. Con sesión, pone el token en `authTokenProvider` y llama a `GET /me`. Con `200` refresca usuario y dispositivo. Con `unauthorized` borra el almacenamiento y devuelve `null`. Con `network_error` (o cualquier otro fallo que no sea `401`) devuelve la sesión guardada.
  - `login(username, password)`: `POST /login` con el nombre del dispositivo, guarda la sesión y fija el token. Si falla, propaga la `ApiException` sin tocar el estado; la pantalla la muestra.
  - `logout()`: `POST /logout` ignorando errores, y después borra almacenamiento, token y sesión. Si no hay red, el token sigue válido en el servidor hasta que caduque (90 días) o se revoque por consola. Se acepta: el móvil ya lo ha olvidado.
  - **Sesión caducada:** escucha `authTokenProvider`. Si el token pasa a `null` con una sesión activa (un `401` en cualquier petición), borra el almacenamiento y pone la sesión a `null`. Así no se necesita que el `ApiClient` conozca la sesión, y no hay ciclo entre providers.

Alternativa descartada: mover todo a un único provider asíncrono. El `ApiClient` necesita leer el token de forma síncrona en cada petición.

### Almacenamiento

`TokenStorage` envuelve `FlutterSecureStorage` con `read()`, `write(Session)` y `clear()`, y guarda tres claves (`token`, `username`, `device_name`). Es una clase concreta. En los tests se sustituye su provider por una versión en memoria que la implementa, sin interfaz aparte.

- Android: opciones por defecto de la versión 11 (clave AES envuelta con RSA en el Keystore) y `android:allowBackup="false"`, porque la documentación del paquete indica que restaurar un backup de Google Drive rompe la clave (`InvalidKeyException`).
- iOS: `KeychainAccessibility.first_unlock_this_device`: no se sincroniza con iCloud ni pasa a otro dispositivo, y se puede leer en segundo plano tras el primer desbloqueo (lo necesitará la subida de audios de la fase 3).

### Nombre del dispositivo

`deviceNameProvider` (`FutureProvider<String>`) con `device_info_plus`:

- Android: `«<fabricante> <modelo> (Android <versión>)»`. El fabricante va en mayúscula inicial y no se repite si el modelo ya lo incluye.
- iOS: `«<modelo comercial> (iOS <versión>)»` (`modelName`, p. ej. «iPhone 16 Pro»; `name` devuelve un genérico «iPhone» sin un permiso especial de Apple).
- Si falla o queda vacío: «MyDiary app». Se recorta a 100 caracteres, el máximo del backend.

### Modelos

`LoginResult` (`token`, `tokenId`, `deviceName`, `expiresAt`) y `Me` (`username`, `tokenId`, `deviceName`, `createdAt`, `lastUsedAt`, `expiresAt`), en `lib/auth/`, con los mismos helpers de JSON.

### Router

Tres estados: cargando → `/splash`; sesión `null` → `/login`; sesión → `/`. `refreshListenable` alimentado por `sessionProvider`. El router ya no mira el token directamente.

### Pantallas

- **Carga** (`/splash`): título y spinner.
- **Login**: `ConsumerStatefulWidget` con `Form`. Usuario (con `autofillHints`), contraseña con botón de mostrar u ocultar, y botón «Entrar», que se desactiva mientras envía y durante la cuenta atrás.
  - El mensaje de error es el `message` de la `ApiException` (el backend ya lo da en castellano).
  - En `429`, «Demasiados intentos. Prueba de nuevo en mm:ss», con un `Timer` cada segundo hasta `Retry-After`. Sin `Retry-After`, 60 s.
  - Validación local: campos no vacíos.
  - En `kDebugMode`, la URL del servidor al pie.
- **Inicio**: menú ⋮ con usuario y dispositivo, y «Cerrar sesión», que pide confirmación en un diálogo.

### Tests

`dioProvider` nuevo (por defecto `Dio()`), que los tests sustituyen por uno con el adaptador falso de la fase 0, movido a `test/support/`. Tests unitarios de `SessionNotifier` con un `ProviderContainer` y tests de widget del flujo completo (carga, login correcto e incorrecto, `429`, logout, `401` en otra petición).

## Risks / Trade-offs

- [Logout sin red deja el token vivo en el servidor] → Caduca a los 90 días sin uso y se revoca con `app:user:token:revoke`.
- [Arranque sin red con un token ya revocado entra al inicio] → El primer `401` cuando vuelva la red lleva al login.
- [`device_info_plus` en el emulador da un modelo poco legible (`sdk_gphone64_x86_64`)] → Solo afecta al nombre que se ve en `app:user:token:list`.
- [En iOS el Keychain sobrevive a desinstalar la app] → Al reinstalar se recupera la sesión, y si el token ya no vale, `/me` da `401` y se borra. Comportamiento aceptable.

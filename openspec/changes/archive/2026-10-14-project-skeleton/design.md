## Context

Repositorio nuevo, solo con documentación (`AGENTS.md`, `ROADMAP.md`, `doc/BACKEND.md`). La API que se va a consumir ya existe y está descrita en `openapi.json` del backend. En el host no hay Flutter, SDK de Android ni un JDK que admita Gradle (solo Java 27); sí hay Docker y `/dev/kvm`. El usuario ha pedido el toolchain en Docker y ha elegido D1 (Riverpod sin codegen), D2 (`go_router`) y D3 (`fromJson` a mano).

Restricciones de `AGENTS.md`: sin capas por feature, un único `ApiClient`, un modelo por esquema de `openapi.json`, nada de lógica de dominio en la app, URL y credenciales fuera del repo.

## Goals / Non-Goals

**Goals:**

- `make up && make test` funciona en una máquina con solo Docker.
- Un APK de debug se construye y se puede instalar en un móvil desde el contenedor.
- El `ApiClient` y los modelos de recursos quedan listos y probados para las fases 1–6.
- La navegación ya redirige al login sin token, para que la fase 1 solo tenga que rellenar la pantalla y guardar el token.

**Non-Goals:**

- Pantallas reales, login real y almacenamiento seguro del token (fase 1).
- Modelos de respuestas propias de un endpoint (`/diario`, `/historial`, `/estadisticas`, `/busqueda`, `/login`, `/me`): cada fase modela las que usa.
- Emulador de Android en Docker, build de iOS (requiere macOS) y firma de release.
- Publicar el repositorio en GitHub: el workflow de CI se deja listo, pero crear el remoto lo decide el usuario.

## Decisions

### Toolchain: imagen propia y contenedor de larga duración

`docker/flutter/Dockerfile` sobre `eclipse-temurin:21-jdk-noble` (JDK 21 soportado por el plugin de Android para Gradle):

- `cmdline-tools` del SDK de Android en `/opt/android-sdk` y Flutter `3.47.7` clonado en `/opt/flutter` (versión fijada con `ARG`, la misma que en CI).
- Usuario `builder` con el UID/GID del host (`ARG`), dueño del SDK y de Flutter, para que los ficheros del proyecto montado no sean de `root` y Gradle pueda instalar componentes del SDK si un día los pide.
- Calentamiento en la imagen: `flutter precache --android` y un `flutter build apk --debug` de un proyecto desechable, para que plataformas, build-tools, NDK y la distribución de Gradle queden en la imagen y el primer `make apk` no descargue cientos de MB. La caché de Gradle y la de pub se montan además como volúmenes con nombre.

`docker-compose.yml` con un servicio `flutter` (contenedor `mydiary-flutter`) que queda vivo (`sleep infinity`) y `network_mode: host`. Los comandos de `make` hacen `exec` sobre él, igual que el backend con `diary-php`.

- **Por qué contenedor vivo y no `run --rm`:** el servidor de `adb` vive dentro del contenedor; con un contenedor por comando se perdería el emparejamiento con el móvil entre `make` y `make`.
- **Por qué red del host:** el backend local escucha en `localhost:9008` y la depuración inalámbrica de Android usa puertos dinámicos en la LAN.

Alternativas descartadas: instalar Flutter y Android Studio en el host (el usuario prefiere Docker); imágenes públicas de terceros (`ghcr.io/cirruslabs/flutter`): sin control de la versión del JDK ni del usuario, y añaden una dependencia externa a mantener.

### Ejecución en móvil

`make adb-pair` y `make adb-connect` envuelven `adb pair` / `adb connect` (depuración inalámbrica, Android 11+), y `make run` lanza `flutter run` con el fichero de entorno. Sin acceso USB ni emulador en esta fase.

### Configuración

`AppConfig.fromEnvironment()` lee `API_BASE_URL` con `String.fromEnvironment`. Si falta o no es una URL `http(s)`, `main()` muestra una pantalla de error de configuración en vez de arrancar contra una URL vacía. Los ficheros `env/*.json` están en `.gitignore`; `env.example.json` documenta la clave. `make` usa `ENV=dev` por defecto (`env/dev.json`).

### Cliente de la API

`ApiClient` envuelve un `Dio` con `baseUrl` `<API_BASE_URL>/api/v1` y expone `get`, `post`, `patch` y `delete` genéricos que reciben una función `parse` (`Object? json → T`). La subida multipart (fase 3) es un `post` con un `FormData` como cuerpo. Las pantallas y providers nunca usan `Dio` directamente.

- **Token:** el cliente recibe una función `String? Function()` que lo lee en cada petición (el estado vive en Riverpod), y añade `Authorization: Bearer` solo si hay token.
- **Errores:** todo fallo sale como `ApiException(statusCode, code, message, retryAfter)`:
  - respuesta con cuerpo `{code, message}` → esos valores;
  - respuesta de error sin ese cuerpo (p. ej. el `413` en HTML de nginx) → `code` derivado del estado según la tabla del backend, o `http_<estado>` si no está en ella;
  - sin respuesta (timeout, sin red, DNS) → `network_error`;
  - respuesta `2xx` que no se puede parsear al modelo esperado → `invalid_response`.
- **`401`:** además de lanzar la excepción, llama a `onUnauthorized`, que en la app borra el token; la redirección del router hace el resto. Se excluye `POST /login`, donde un `401` es "credenciales incorrectas" y no "sesión caducada".
- **`429`:** `retryAfter` con la cabecera `Retry-After` en segundos.
- Timeouts: 10 s de conexión, 30 s de recepción. La subida de audio (fase 3) ajustará el suyo.

Tests con un `HttpClientAdapter` falso escrito en el propio test, sin paquete de mocks.

### Modelos

Clases inmutables con `final` y `factory X.fromJson(Map<String, Object?>)`, una por esquema de `openapi.json` (la página genérica se llama `Paginated<T>` para no chocar con `Page` de Flutter), con los campos en `camelCase` mapeados explícitamente desde el `snake_case` de la API. Utilidades comunes en `lib/api/json.dart`:

- **Instantes** → `DateTime` en UTC (`DateTime.parse` de `...Z`). La conversión a local es cosa de la vista.
- **Días** (`AAAA-MM-DD`) → `DateTime(año, mes, día)` sin hora, construido a mano y nunca con `DateTime.parse` + conversión de zona. Se documenta en el propio helper.
- **Enums** (`AudioStatus`, `AudioSource`, `SummaryGenerationStatus`) con un valor `unknown` para valores futuros del backend, en vez de fallar.
- `Reminder.time` queda como `String?` (`HH:MM`); se convertirá a un tipo de UI cuando haya formulario (fase 6).

Cualquier `TypeError`/`FormatException` al parsear se convierte en `ApiException('invalid_response')` dentro del `ApiClient`.

### Estado y navegación (D1, D2)

- `authTokenProvider`: `Notifier<String?>` en memoria. En la fase 1 se le añadirá la persistencia en `flutter_secure_storage` sin cambiar su interfaz de lectura.
- `apiClientProvider`: construye el `ApiClient` a partir de la configuración y del token.
- `routerProvider`: `GoRouter` con `/login` y `/`, `redirect` según el token y `refreshListenable` alimentado por el `authTokenProvider`.

### Calidad, CI y hooks

- `analysis_options.yaml`: `flutter_lints` más `strict-casts`, `strict-inference` y `strict-raw-types`, que obligan a que los `fromJson` hagan los casts explícitos.
- CI (`.github/workflows/ci.yml`) con `subosito/flutter-action` y la misma versión de Flutter: `dart format --set-exit-if-changed`, `flutter analyze` y `flutter test`. No usa la imagen Docker: `flutter test` no necesita el SDK de Android y así la CI tarda poco.
- `.githooks/pre-commit`: comprueba el formato de los `.dart` en stage con el contenedor; si no está levantado, avisa y no bloquea.
- `.claude/settings.json`: la misma guarda del backend contra `git commit` en `develop`/`main` y un hook que formatea con `dart format` el `.dart` editado (sin efecto si el contenedor no está levantado).

## Risks / Trade-offs

- [Imagen grande (unos 9 GB) y primera construcción lenta (unos 15 min)] → Se construye una vez. Las cachés en volúmenes sobreviven a reconstrucciones del contenedor.
- [UID fijado al construir] → `make build` pasa `$(id -u)`/`$(id -g)`. Otro usuario reconstruye la imagen.
- [La depuración inalámbrica pide emparejar de nuevo de vez en cuando] → `make adb-pair`. Si molesta, añadir USB (`/dev/bus/usb`) en otro cambio.
- [Sin emulador ni build de iOS en local] → Fuera de alcance. Hay KVM para un emulador en Docker si se pide, e iOS necesita macOS en cualquier caso.
- [Fixtures escritas a mano a partir de `openapi.json`] → Pueden desviarse del backend real. Se revisan contra respuestas reales en las fases que consumen cada modelo.

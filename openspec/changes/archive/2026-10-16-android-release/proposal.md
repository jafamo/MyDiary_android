## Why

El usuario quiere instalar la app desde Google Play (decisión: canal de **prueba interna**, sin revisión ni los 12 testers de la prueba cerrada). Hoy solo hay un APK de debug: firmado con la clave de depuración, contra el backend local y con el icono de Flutter.

## What Changes

- **Firma de publicación**: clave de subida (`android/upload-keystore.jks`) y `android/key.properties`, los dos fuera de git (ya los ignora `android/.gitignore`). `make keystore` la genera con `keytool` del contenedor (las contraseñas las escribe el usuario). Con Play App Signing, Google guarda la clave de firma final.
- **Builds de release**: `make appbundle` (AAB para Play) y `make apk-release` (para probar el build de release en el emulador). Los dos exigen `key.properties` (no se firma una release con la clave de debug) y una `API_BASE_URL` `https` (`ENV=prod`, `env/prod.json` no versionado).
- **Icono** (decisión del usuario: ondas de voz): barras de onda blancas sobre el verde azulado de la web (`#14968A`). Icono adaptativo en vector (Android 8+), con capa monocroma para los iconos temáticos de Android 13, PNG para Android 7 e icono de 512 px para la ficha de Play. Fuente SVG en `doc/icon/`.
- **Tema** (decisión del usuario): `colorSchemeSeed` pasa de índigo a `#14968A`, el color de la web.
- **Política de privacidad** (decisión del usuario: en este repo): `PRIVACY.md`, enlazada por su URL de GitHub en la ficha de Play.
- **Guía de publicación** `doc/RELEASE.md`: cuenta de Play Console, clave, build, ficha, formularios (seguridad de los datos, servicio en primer plano de reproducción, permisos) y prueba interna.

## Capabilities

### New Capabilities

- `release`: build de publicación firmado para Google Play.

### Modified Capabilities

(ninguna)

## Impact

- `android/app/build.gradle.kts` (firma), `Makefile`, recursos `android/app/src/main/res/` (icono), `lib/app.dart` (color), `PRIVACY.md`, `doc/RELEASE.md`, `doc/icon/`.
- Sin dependencias nuevas: el icono es un vector escrito a mano y los PNG se generan una vez desde el SVG.
- La primera subida fija para siempre el identificador `com.jfarinos.mydiary`.
- La versión que se suba sale de una release de Git Flow (`0.1.0`), fuera de este cambio.

# release Specification

## Purpose
TBD - created by archiving change android-release. Update Purpose after archive.
## Requirements
### Requirement: Build de publicación firmado
`make appbundle` SHALL generar un AAB de release y `make apk-release` un APK de release, los dos firmados con la clave de subida indicada en `android/key.properties`. Sin ese fichero, los dos SHALL fallar con un mensaje que explique cómo crear la clave, sin firmar con la clave de debug. La clave y `key.properties` MUST NOT versionarse.

#### Scenario: Sin clave
- **WHEN** se ejecuta `make appbundle` sin `android/key.properties`
- **THEN** falla indicando `make keystore`

#### Scenario: Con clave
- **WHEN** existe `android/key.properties` y se ejecuta `make appbundle ENV=prod`
- **THEN** se genera `build/app/outputs/bundle/release/app-release.aab` firmado con la clave de subida

### Requirement: Solo HTTPS en las builds de publicación
Los objetivos de release SHALL negarse a compilar si `API_BASE_URL` del entorno elegido no empieza por `https://`.

#### Scenario: URL local
- **WHEN** se ejecuta `make appbundle` con `env/dev.json` (`http://10.0.2.2:9008`)
- **THEN** falla indicando que hace falta una URL `https` (`ENV=prod`)

### Requirement: Icono de la app
La app SHALL usar como icono unas ondas de voz blancas sobre `#14968A`: adaptativo (con capa monocroma) en Android 8 o superior y en PNG en Android 7.

#### Scenario: Lanzador
- **WHEN** se instala la app
- **THEN** el lanzador muestra el icono de ondas de voz con el nombre «MyDiary»


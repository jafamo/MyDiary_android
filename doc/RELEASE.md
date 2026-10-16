# Publicar en Google Play (Android)

La app se distribuye por el canal de **prueba interna** de Google Play: hasta 100 testers invitados por email, sin revisión de Google y sin la prueba cerrada (12 testers durante 14 días) que se exige a las cuentas personales nuevas para publicar en producción. Se instala y se actualiza desde la Play Store como cualquier app.

## Una sola vez

### 1. Cuenta de Google Play Console

Alta en <https://play.google.com/console> como cuenta **personal**: 25 USD (un solo pago) y verificación de identidad. Puede tardar unos días.

### 2. Clave de subida

```bash
make keystore
```

Pide una contraseña y crea `android/upload-keystore.jks` y `android/key.properties`. **Ninguno de los dos se versiona** (`android/.gitignore`) y el repositorio es público: no copiarlos a ningún sitio dentro del repo.

Guarda una copia de los dos ficheros fuera del repo (p. ej. en el gestor de contraseñas). Google Play firma la app con su propia clave (Play App Signing, por defecto en las apps nuevas); la clave de subida solo demuestra que el AAB es tuyo. Si se pierde, se puede pedir otra en Play Console (*Prueba y publicación › Integridad de la app*), pero hay que esperar a que Google la apruebe.

### 3. Entorno de producción

`env/prod.json` (no versionado), con la URL pública del backend (`APP_PUBLIC_URL` del backend en zeus), sin `/api/v1`:

```json
{
  "API_BASE_URL": "https://…"
}
```

Las builds de publicación se niegan a compilar sin clave o con una URL que no sea `https`.

### 4. Crear la app en Play Console

*Crear app*: nombre **MyDiary**, idioma predeterminado **español (España)**, **App**, **Gratis**.

El identificador `com.jfarinos.mydiary` queda fijado con la primera subida y no se puede cambiar.

### 5. Contenido de la app (*Política › Contenido de la app*)

| Apartado | Respuesta |
|---|---|
| Política de privacidad | `https://github.com/jafamo/MyDiary_android/blob/main/PRIVACY.md` (está en `main` tras la primera release; hasta entonces, la misma ruta en `develop`) |
| Acceso a la app | Toda la app requiere una cuenta en un servidor privado; no hay cuenta de prueba |
| Anuncios | No contiene anuncios |
| Clasificación del contenido | Cuestionario: categoría «Utilidades / productividad», sin contenido sensible |
| Público objetivo | Mayores de 18 años |
| Seguridad de los datos | Ver abajo |
| Permisos de servicio en primer plano | `FOREGROUND_SERVICE_MEDIA_PLAYBACK`: reproducir notas de voz con la pantalla apagada o fuera de la app, iniciado por el usuario al pulsar ▶. Si lo pide, un vídeo corto escuchando una nota y bloqueando la pantalla |
| App de noticias, gubernamental, salud, etc. | No |

**Seguridad de los datos** (orientativo; los datos solo viajan al servidor del propio usuario, cifrados):

- Recoge: **Audio › Grabaciones de voz o sonido** (funcionalidad de la app) y **Información personal › IDs de usuario** (el nombre de usuario del login).
- No comparte datos con terceros.
- Cifrados en tránsito: sí (HTTPS).
- El usuario puede pedir que se eliminen: sí (los borra desde la web; la cuenta la gestiona el administrador del servidor).

### 6. Ficha de Play Store (*Crecimiento › Presencia en Play Store*)

- Descripción breve: «Tu diario en notas de voz: grábalas, escúchalas y lee sus transcripciones y resúmenes.»
- Icono: [`doc/icon/play-icon-512.png`](icon/play-icon-512.png). Gráfico destacado: [`doc/icon/feature-graphic.png`](icon/feature-graphic.png).
- Capturas de móvil: al menos 2 (desde el emulador: `docker exec mydiary-flutter adb exec-out screencap -p > captura.png`). Sin datos personales.

## Cada versión

1. Release con Git Flow (ver `AGENTS.md`): `version: X.Y.Z+N` en `pubspec.yaml`, subiendo **siempre** el número de build `N` (Play rechaza un build repetido), CHANGELOG y tag.
2. Probar la build de release en el emulador (opcional): `make apk-release ENV=prod` y `adb install -r build/app/outputs/flutter-apk/app-release.apk`.
3. `make appbundle ENV=prod` → `build/app/outputs/bundle/release/app-release.aab`.
4. Play Console › *Prueba y publicación › Pruebas › Prueba interna* › *Crear versión*: subir el AAB, notas de la versión (del CHANGELOG) y *Guardar y publicar*.
5. La primera vez, en *Testers*: crear una lista con los emails de las cuentas de Google que van a instalarla y abrir el **enlace de participación** desde el móvil con esa cuenta. Después se instala y se actualiza desde la Play Store.

Si la versión usa algo nuevo de la API, el backend de producción tiene que estar en la versión mínima indicada en el CHANGELOG (`Requiere backend`) antes de publicarla.

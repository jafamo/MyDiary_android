# Política de privacidad de MyDiary

Última actualización: 15 de octubre de 2026.

MyDiary es la app móvil de un diario personal por notas de voz. Es un proyecto personal sin ánimo de lucro: la app no tiene publicidad, no usa analítica ni rastreo y no vende ni comparte datos con terceros.

## Cómo funciona

La app es un cliente de un **servidor MyDiary privado**, que administra su propio usuario. No hay registro: solo pueden entrar las cuentas creadas en ese servidor. Todo lo que la app envía va únicamente a ese servidor, siempre cifrado por HTTPS.

## Qué datos trata la app

- **Usuario y contraseña**: solo para iniciar sesión. La contraseña no se guarda en el dispositivo.
- **Token de sesión**: lo devuelve el servidor al iniciar sesión y se guarda en el almacenamiento seguro del sistema (Android Keystore / iOS Keychain). Se borra al cerrar sesión.
- **Nombre del dispositivo** (p. ej. «Google Pixel 7 (Android 16)»): se envía al iniciar sesión para identificar la sesión en el servidor.
- **Notas de voz**: con el permiso de micrófono, la app graba solo cuando el usuario pulsa grabar y sube la grabación al servidor. Las notas que se escuchan se descargan a un fichero temporal que se borra al terminar.

## Qué hace el servidor con los datos

El servidor guarda las notas de voz, las transcribe a texto y genera resúmenes diarios, temas, búsquedas y estadísticas con servicios de inteligencia artificial elegidos por el administrador del servidor. También puede enviar avisos (p. ej. que una nota no se pudo transcribir) por Telegram al propio usuario.

## Permisos

- **Micrófono**: grabar notas de voz, solo a petición del usuario.
- **Internet**: comunicarse con el servidor.
- **Servicio en primer plano de reproducción multimedia**: seguir escuchando una nota con la pantalla apagada o fuera de la app, con controles en la notificación.

## Conservación y borrado

Los datos se conservan en el servidor hasta que el usuario los elimina desde la web o la app de MyDiary, o hasta que el administrador del servidor borra la cuenta. Al cerrar sesión en la app se borran del dispositivo el token y la sesión.

## Menores

La app no está dirigida a menores de 13 años.

## Contacto

Para cualquier duda sobre esta política, abre una incidencia en <https://github.com/jafamo/MyDiary_android/issues>.

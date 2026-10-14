## 1. Dependencias y plataforma

- [x] 1.1 `flutter_secure_storage` y `device_info_plus`
- [x] 1.2 `android:allowBackup="false"`

## 2. Sesión

- [x] 2.1 Modelos `LoginResult` y `Me`, con tests de parseo
- [x] 2.2 `TokenStorage` (Keystore/Keychain, accesibilidad `first_unlock_this_device`) y su provider
- [x] 2.3 `deviceNameProvider` (formato, recorte a 100, valor por defecto) con tests del formato
- [x] 2.4 `dioProvider` y adaptador HTTP falso compartido en `test/support/`
- [x] 2.5 `SessionNotifier`: arranque con `/me` (200, 401, sin red), `login`, `logout` (también sin red) y sesión caducada por `401`
- [x] 2.6 Tests unitarios de `SessionNotifier`

## 3. Navegación y pantallas

- [x] 3.1 Router con `/splash`, `/login` y `/` según `sessionProvider`
- [x] 3.2 Pantalla de carga
- [x] 3.3 Login: validación local, errores del backend, cuenta atrás del `429`, servidor en debug
- [x] 3.4 Inicio con menú ⋮ (usuario, dispositivo, cerrar sesión con confirmación)
- [x] 3.5 Tests de widget del flujo: carga, login correcto, error, `429`, logout, cancelar logout, `401` en otra petición

## 4. Verificación

- [x] 4.1 `make format-check`, `make analyze`, `make test`
- [x] 4.2 En el emulador contra el backend local: login, reabrir la app y token revocado por consola (el logout desde el menú, cubierto por los tests de widget)

## 5. Cierre

- [x] 5.1 `AGENTS.md`/`doc/BACKEND.md` si aplica, `ROADMAP.md` y `CHANGELOG.md`
- [x] 5.2 Validar, archivar, commit y `git flow feature finish`

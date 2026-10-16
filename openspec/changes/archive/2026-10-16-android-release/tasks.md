## 1. Firma y builds

- [x] 1.1 Firma de release con `key.properties` en `build.gradle.kts`
- [x] 1.2 `make keystore`, `make appbundle` y `make apk-release`, con sus comprobaciones

## 2. Identidad

- [x] 2.1 Icono adaptativo, monocromo, PNG para Android 7 y 512 px para Play
- [x] 2.2 Tema con el color de la web

## 3. Documentación

- [x] 3.1 `PRIVACY.md`
- [x] 3.2 `doc/RELEASE.md`, `AGENTS.md` y `README.md`

## 4. Verificación

- [x] 4.1 `make format-check`, `make analyze`, `make test`
- [x] 4.2 `make apk-release` firmado con una clave de prueba e instalado en el emulador; icono en el lanzador

## 5. Cierre

- [x] 5.1 `CHANGELOG.md`
- [x] 5.2 Validar, archivar, commit, `git flow feature finish` y push de `develop`

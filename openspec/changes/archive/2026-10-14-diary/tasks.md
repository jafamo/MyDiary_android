## 1. Dependencias e idioma

- [x] 1.1 `flutter_localizations` e `intl`; `MaterialApp` en `es`
- [x] 1.2 `lib/format.dart` (día, hora local, duración) con tests

## 2. Datos

- [x] 2.1 Modelo `Diary` (`Streak`, `Week`, `TopTopic`, `needsPolling`) con fixture y tests de parseo
- [x] 2.2 `diaryFilterProvider` y `diaryProvider` (`status`, `autoDispose`, sin reintento automático) con tests
- [x] 2.3 `/diario` en el backend falso de los tests

## 3. Navegación

- [x] 3.1 `StatefulShellRoute` con Diario, Historial, Buscar y Más; `HomeScreen` con la barra inferior
- [x] 3.2 Pantallas provisionales de Historial, Buscar y Más

## 4. Portada

- [x] 4.1 Cabecera y cifras
- [x] 4.2 Resumen plegable con estados de la generación
- [x] 4.3 Filtro por estado
- [x] 4.4 Entradas con «Ver más» y estados vacíos
- [x] 4.5 Refresco: deslizar, sondeo cada 10 s con las condiciones, al volver a la app, y errores con y sin datos
- [x] 4.6 Tests de widget: cifras, resumen, entradas, filtro, sondeo (con y sin pendientes), error con datos, error inicial y reintento, cambio de pestaña

## 5. Verificación

- [x] 5.1 `make format-check`, `make analyze`, `make test`
- [x] 5.2 En el emulador contra el backend local (sin audios de hoy: portada vacía; las entradas y el sondeo, cubiertos por los tests de widget)

## 6. Cierre

- [x] 6.1 `ROADMAP.md` y `CHANGELOG.md`
- [x] 6.2 Validar, archivar, commit y `git flow feature finish`

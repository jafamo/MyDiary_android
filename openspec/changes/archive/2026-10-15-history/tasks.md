## 1. Modelos y API

- [x] 1.1 `HistoryMonth` y `HistoryDay` con tests de parseo (fixtures `history_month.json` y `history_day.json`)
- [x] 1.2 Providers del mes y del día

## 2. Interfaz

- [x] 2.1 Extraer los widgets del Diario a `entry_widgets.dart` y el aviso de error al escuchar a `HomeScreen`
- [x] 2.2 Calendario: rejilla, marcas, hoy, cambio de mes con flechas y deslizando, error y recarga
- [x] 2.3 Pantalla del día en `/historial/:fecha`: resumen, filtro, notas con ▶, recarga
- [x] 2.4 Tests de widget
- [x] 2.5 Flechas al día con notas anterior y siguiente (`previous_date`/`next_date`, nuevos en el backend)

## 3. Verificación

- [x] 3.1 `make format-check`, `make analyze`, `make test`
- [x] 3.2 En el emulador: navegar meses, abrir un día con resumen, saltar con las flechas y escuchar (el Ogg de Telegram queda pendiente: los audios de prueba locales no tienen fichero)

## 4. Cierre

- [x] 4.1 `ROADMAP.md` y `CHANGELOG.md`
- [x] 4.2 Validar, archivar, commit, `git flow feature finish` y push de `develop`

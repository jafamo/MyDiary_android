## Why

Primera parte de la fase 5 de `ROADMAP.md`. La app solo enseña el Diario de hoy: para ver lo grabado otros días hay que ir a la web. El backend ya da el calendario (`GET /api/v1/historial?month=`) y el detalle de un día (`GET /api/v1/historial/{fecha}`).

## What Changes

- **Sección Historial** (sustituye al «Llega en una próxima versión»): calendario del mes a pantalla completa, de lunes a domingo, con `‹`/`›` y deslizamiento lateral para cambiar de mes. Pasar del mes actual no se puede.
- **Marcas de los días** (decisión del usuario): bajo el número, una pastilla redondeada de color con el nº de notas y un punto si el día tiene resumen. Si un día tiene resumen pero ninguna nota, solo el punto. Hoy va rodeado. Solo los días con actividad se pueden tocar.
- **Pantalla del día** (decisión del usuario: calendario → otra pantalla) en `/historial/AAAA-MM-DD`, sin perder la barra inferior: fecha con el año, nº de audios, resumen, filtro por estado y las notas con ▶, igual que en el Diario. Deslizar para recargar.
- **Saltar al día con notas anterior o siguiente** (petición del usuario al probarlo): `‹`/`›` junto a la fecha, con `previous_date`/`next_date`, que se añadieron al backend para esto (`history-adjacent-days` en MyDiary, en `develop`). Con un backend anterior, las flechas salen desactivadas.
- Las tarjetas de nota y resumen, el filtro y el error de carga del Diario pasan a un fichero compartido para usarlos en las dos pantallas. El aviso de error al escuchar sale una sola vez desde el contenedor de las secciones (con dos pantallas escuchando, salía repetido).

## Capabilities

### New Capabilities

- `history`: calendario por meses con los días con actividad y detalle de un día.

### Modified Capabilities

- `app-shell`: la sección Historial ya tiene contenido.

## Impact

- Código: `lib/history/` (modelos de las dos respuestas, providers, calendario y pantalla del día), `lib/diary/entry_widgets.dart` (extraído de `diary_screen.dart`), ruta hija `/historial/:fecha` en `router.dart` y el aviso de reproducción en `home_screen.dart`.
- Sin dependencias nuevas: el calendario es propio (`ROADMAP.md`). Backend: `previous_date`/`next_date` en `GET /api/v1/historial/{fecha}` (MyDiary `develop`, posterior a 0.19.0); el resto funciona con 0.19.0.
- Los audios Ogg/Opus de Telegram se pueden escuchar desde aquí en Android; en iOS siguen pendientes (D4, fase 8).

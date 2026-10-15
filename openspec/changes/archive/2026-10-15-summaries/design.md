## Context

`GET /api/v1/resumenes` devuelve `{items, page, per_page, total}`; `from` y `to` van los dos o ninguno (si no, `422`).

## Decisions

- **Provider paginado propio**: `AsyncNotifier` por rango (`family`) que guarda los resúmenes cargados, el `total` y si está pidiendo la siguiente página o ha fallado. La primera página es el estado `AsyncValue` (carga y error a pantalla completa); las siguientes no tocan lo ya cargado. Sin paquete de paginación: es una sola lista.
- **Cuándo pedir la siguiente página**: al construirse el pie de la lista (el último elemento), si quedan más y no hay una petición en curso ni un error. Con un error, el pie enseña «Reintentar» y no vuelve a pedir solo.
- **Ruta hija de «Más»** (`/mas/resumenes`) para conservar la barra inferior, como el día del Historial. El chip de audios va a `/historial/AAAA-MM-DD`, que cambia a la pestaña Historial.
- **Rango con `showDateRangePicker`** de Material (en español, con `flutter_localizations`), hasta hoy (la fecha del Diario o, si no ha cargado, la del dispositivo).

## Risks / Trade-offs

- Si llegan resúmenes nuevos mientras se pagina, puede repetirse uno en el corte entre páginas: se descartan los repetidos por `id`.

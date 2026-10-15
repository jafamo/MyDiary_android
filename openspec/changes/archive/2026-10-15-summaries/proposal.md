## Why

Segunda parte de la fase 5 de `ROADMAP.md`. Para releer los resúmenes de días anteriores hay que abrirlos uno a uno en el Historial o ir a la web. El backend ya los da en una lista paginada (`GET /api/v1/resumenes?from=&to=`), con el nº de audios de cada día.

## What Changes

- **«Más» pasa a ser un menú** (decisión del usuario): Resúmenes abre su pantalla (`/mas/resumenes`, sin perder la barra inferior); Recordatorios, Estadísticas y Temas siguen como «Próximamente».
- **Lista de resúmenes** del más reciente al más antiguo. Cada tarjeta (decisión del usuario: plegados) enseña la fecha con el año, un chip con el nº de audios y las tres primeras líneas del texto. Tocarla la despliega con el texto completo, la leyenda de emojis, los temas y las métricas de la IA (modelo, tokens y tiempo; «—» si faltan). El chip abre ese día en el Historial.
- **Scroll infinito** (decisión del usuario): 20 por página; al llegar abajo se piden los siguientes. Si falla una página, aviso al final con «Reintentar» sin perder lo cargado. Deslizar hacia abajo recarga desde el principio.
- **Filtro por fechas**: el icono 📅 abre el selector de rango de Material; el rango elegido se envía como `from`/`to` y queda en un chip con ✕ para quitarlo.

## Capabilities

### New Capabilities

- `summaries`: lista paginada de resúmenes con filtro por rango de fechas.

### Modified Capabilities

- `app-shell`: «Más» es un menú con las secciones restantes.

## Impact

- Código: `lib/summaries/` (provider paginado y pantalla), modelo `SummaryListItem` (el `Summary` con `audio_count`) en `lib/models/summary.dart`, la leyenda y los temas de `SummaryCard` extraídos a un widget compartido, `more_screen.dart` y la ruta `/mas/resumenes`.
- Sin dependencias nuevas ni cambios en el backend (funciona con 0.19.0).

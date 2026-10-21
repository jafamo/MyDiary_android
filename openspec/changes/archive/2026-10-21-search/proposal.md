## Why

Tercera parte de la fase 5 de `ROADMAP.md`. La pestaña Buscar de la barra inferior todavía dice «Llega en una próxima versión». El backend ya ofrece la búsqueda semántica en transcripciones y resúmenes, y por texto en recordatorios (`GET /api/v1/busqueda?q=`).

## What Changes

- **Pantalla Buscar** (`/buscar`): campo de búsqueda arriba con texto de ayuda «¿Cuándo hablé de...?» y botón para borrarlo.
- **Se busca al enviar** (decisión del usuario): con la lupa del teclado, no mientras se escribe. La búsqueda semántica pide los embeddings a la IA del servidor en cada consulta.
- **Resultados como en la web, con ▶** (decisión del usuario): primero los recordatorios que coinciden (fecha, hora y texto) y después las notas y los resúmenes, del más parecido al menos parecido.
  - Las notas usan la tarjeta del Diario (▶, duración, estado y texto plegado con «Ver más») con la fecha del día delante de la hora.
  - Los resúmenes salen plegados a 4 líneas con «Ver más», y al desplegarse enseñan la leyenda de emojis y los temas.
  - Cada nota y resumen tiene «Ver día» para abrir ese día en el Historial.
- **Sin búsquedas recientes** (decisión del usuario): no se guarda nada en el móvil.
- Estados: ayuda antes de buscar, carga, «Sin resultados para «…»» y error con «Reintentar». La búsqueda se conserva al cambiar de pestaña.

## Capabilities

### New Capabilities

- `search`: búsqueda en notas, resúmenes y recordatorios.

### Modified Capabilities

- `app-shell`: ya no queda ninguna sección de la barra inferior sin contenido.

## Impact

- Código: `lib/search/` (provider y pantalla), modelo `SearchResults` en `lib/models/search.dart`, `EntryCard` con la fecha opcional y acción opcional, texto plegable compartido, ruta `/buscar`. Se borra `UpcomingScreen`, que ya no usa nadie.
- Sin dependencias nuevas ni cambios en el backend (funciona con 0.19.0).

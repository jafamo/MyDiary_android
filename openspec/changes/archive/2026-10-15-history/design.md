## Context

- `GET /api/v1/historial?month=AAAA-MM` → `month`, `previous_month`, `next_month` y `days [{date, audio_count, has_summary}]`, solo los días con datos. La rejilla la pinta la app. Sin `month`, el mes actual.
- `GET /api/v1/historial/{fecha}?status=` → `date`, `entries [Audio]` y `summary` (o `null`). Un día vacío es `200` con listas vacías.

## Decisions

- **Calendario a pantalla completa y el día en otra pantalla** (elegido por el usuario frente a «calendario + día debajo» y «lista de días»). La pantalla del día es una ruta hija de la rama del Historial (`/historial/2026-10-14`), así que conserva la barra inferior y el mes que se estaba viendo al volver.
- **Marca:** pastilla redondeada (`primaryContainer`) con el nº de notas y un punto (`tertiary`) si hay resumen (elegido por el usuario; pidió que el número se distinga del día del calendario).
- **Calendario propio**, sin paquete: es una rejilla de 7 columnas y la API ya da los días con datos.
- **Hoy** es la fecha del Diario (`date` de `/diario`, lo decide el servidor); si todavía no ha cargado, la del dispositivo. Sirve para rodear el día y para no pasar del mes actual.
- **Meses:** `‹`/`›` llevan a `previous_month`/`next_month` de la respuesta; el deslizamiento lateral hace lo mismo. Un `FutureProvider.autoDispose.family` por mes (`null` = el actual).
- **Día:** `FutureProvider.autoDispose.family` por fecha y filtro. El filtro es estado de la pantalla, no global: cada día empieza en «Todos». Sin sondeo (es historia; para hoy está el Diario): deslizar para recargar.
- **Widgets compartidos** en `lib/diary/entry_widgets.dart`: `EntryCard`, `SummaryCard`, `StatusFilter` (con `onSelected`), `LoadError`, `RefreshErrorBanner`. El Diario no cambia de aspecto.
- **Aviso de error al escuchar** en `HomeScreen`: `ScaffoldMessenger` es el de la app, y con el Diario y el día escuchando a la vez el aviso salía dos veces.

## Risks / Trade-offs

- Un mes sin actividad muestra la rejilla vacía, sin aviso: es lo esperado.
- Si el mes cambia con la app abierta (medianoche del último día), el `›` no se habilita hasta que el Diario recarga.

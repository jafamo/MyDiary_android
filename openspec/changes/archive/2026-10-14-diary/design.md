## Context

Tras la fase 1, `/` es un inicio provisional con el menú ⋮ de la cuenta. `GET /api/v1/diario?status=` devuelve en una sola respuesta todo lo de la portada: `date`, `entries` (`[Audio]` con transcripción), `summary`, `summary_generation`, `streak`, `week` y `top_topic`.

Decisiones del usuario para esta fase:

- Portada con el resumen arriba, según el mockup.
- Refresco automático mientras haya algo en curso, además de deslizar.
- Barra inferior desde ya.

## Goals / Non-Goals

**Goals:**

- Ver de un vistazo los audios de hoy, su estado y el resumen, y que lo pendiente se actualice solo.
- Dejar la navegación principal lista para las secciones de la fase 5.

**Non-Goals:**

- Reproducir audios (fase 4).
- Editar, eliminar, reintentar o generar el resumen (fase 6).
- Métricas técnicas (modelo, tokens, tiempos de proceso) que muestra la web.
- Caché local: cada apertura pide `/diario`.

## Decisions

### Modelo

`Diary` en `lib/models/diary.dart`, con `date` (día de calendario), `entries`, `summary`, `summaryGeneration`, `streak`, `week` y `topTopic`. `Streak` (`current`, `best`), `Week` (`total`, `delta`) y `TopTopic` (`name`, `count`) son objetos propios de esta respuesta y van en el mismo fichero. Reutiliza `Audio`, `Summary` y `SummaryGeneration`.

`Diary.needsPolling`: algún audio `pending` o una generación del resumen en curso. Es una lectura del estado que da el backend, no lógica de dominio.

### Estado

- `diaryFilterProvider` (`Notifier<AudioStatus?>`): filtro elegido, `null` = todos.
- `diaryProvider` (`FutureProvider.autoDispose<Diary>`): observa el filtro y pide `/diario` con `status` si hay filtro.
  - `autoDispose`: al cerrar sesión se descartan los datos.
  - `retry: null`: sin el reintento automático de Riverpod 3. Un error se muestra y se reintenta a mano, deslizando o con el siguiente sondeo.
- Al cambiar el filtro o recargar, Riverpod conserva el valor anterior: la pantalla sigue mostrando los datos con una barra de progreso fina y no parpadea.

### Sondeo

Lo gestiona la pantalla (`ConsumerStatefulWidget`):

- `Timer.periodic` de 10 s, el mismo intervalo que la web. En cada tick recarga solo si:
  - los últimos datos tienen `needsPolling`;
  - la app está en primer plano (`AppLifecycleListener`);
  - la pestaña está visible (`TickerMode`, que `StatefulShellRoute` desactiva en las ramas ocultas);
  - no hay ya una carga en marcha.
- Al volver a primer plano (`onResume`), recarga siempre.
- Con un filtro que oculta los pendientes (p. ej. «Error»), no se sondea: solo cuenta lo visible. Se acepta, porque el usuario ha elegido mirar otra cosa.

Alternativa descartada: el timer dentro del provider. Necesitaría conocer el ciclo de vida de la app y la pestaña visible, que son de la UI.

### Errores

- Sin datos todavía: pantalla de error con el `message` de la `ApiException` y botón «Reintentar».
- Con datos: se siguen mostrando, con un aviso arriba («No se pudo actualizar.» y el mensaje) hasta la siguiente carga correcta.
- `401`: lo resuelve la fase 1 (vuelta al login).

### Pantalla (`lib/diary/diary_screen.dart`)

`RefreshIndicator` con un `ListView`. De arriba abajo:

1. **Cabecera**: «Miércoles, 14 de octubre» (fecha de `date`, sin conversión de zona) · «3 audios».
2. **Cifras**: tres bloques en una fila.
   - 🔥 «4 días» y «mejor: 12».
   - 🎙 «9 esta semana» y «+2 vs. anterior», «−2 vs. anterior» o «igual que la anterior».
   - 🏷 tema del mes y «6 menciones». Sin tema: «—» y «sin resúmenes este mes».
3. **Resumen**: tarjeta plegable, desplegada al abrir.
   - Cabecera: «Resumen del día · 21:40».
   - Contenido: texto, leyenda de emojis y chips de temas.
   - Si la generación está en curso: «Generando el resumen…». Si ha fallado: «No se pudo generar el resumen (HH:mm)».
   - Sin resumen ni generación: «Todavía no hay resumen de hoy.»
4. **Filtro**: `ChoiceChip` Todos, Pendiente, Transcrito, Error.
5. **Entradas**, en el orden del backend, cada una en una tarjeta:
   - Cabecera: hora local de `received_at`, duración `m:ss` y estado («Transcrito», «Transcribiendo…», «Error»).
   - Transcrito: el texto, plegado a 4 líneas con «Ver más» / «Ver menos» si no cabe.
   - Pendiente: «Transcripción en curso…».
   - Error: `error_message` (o «Error en la transcripción» si falta), en el color de error.
   - Sin entradas: «Sin audios hoy.», o «Ningún audio con este estado.» si hay filtro.

El menú ⋮ de la cuenta pasa a la barra superior del Diario sin cambios.

### Navegación

`StatefulShellRoute.indexedStack` con cuatro ramas: `/` (Diario), `/historial`, `/buscar` y `/mas`. `HomeScreen` pasa a ser el contenedor con la `NavigationBar` y la rama activa.

- Historial y Buscar: pantalla con el título y «Llega en una próxima versión.».
- Más: lista de Resúmenes, Recordatorios, Estadísticas y Temas, desactivadas con «Próximamente».

La redirección según la sesión no cambia: las cuatro rutas exigen sesión.

### Formato

`lib/format.dart`, con el idioma fijo en `es` (la app solo está en español):

- `formatDay` («miércoles, 14 de octubre», con mayúscula inicial en la cabecera).
- `formatTime` (instante UTC → `HH:mm` local).
- `formatDuration` (`m:ss`).

`MaterialApp` con `locale: es` y los delegados de `flutter_localizations`, que además cargan los datos de fechas de `intl` para `es`.

## Risks / Trade-offs

- **Sondeo con el móvil quieto en la portada**: una petición cada 10 s mientras haya algo pendiente. Termina en cuanto el backend transcribe, y no corre en segundo plano.
- **Con filtro, no se ven los audios nuevos que no encajan.** Es lo esperado de un filtro.
- **La fecha la decide el backend**: al pasar la medianoche con la app abierta, la portada cambia de día en la siguiente recarga, no en el momento exacto.

## Why

Fase 2 de `ROADMAP.md`. Tras el login, la app solo muestra un texto provisional. La portada del Diario es lo que más se consulta: qué audios han llegado hoy, si ya están transcritos y el resumen del día.

## What Changes

- **Portada del Diario** con `GET /api/v1/diario`:
  - Cabecera con la fecha de hoy (la que da el backend) y el número de audios.
  - Cifras compactas: racha (actual y mejor), audios de la semana con la diferencia respecto a la anterior y tema del mes.
  - Resumen del día plegable, con leyenda de emojis y temas. Si se está generando o ha fallado, se indica.
  - Filtro por estado (Todos, Pendiente, Transcrito, Error) con el parámetro `status`.
  - Entradas con hora local, duración, estado y transcripción, plegada a unas líneas con «Ver más». Las pendientes y las de error muestran su aviso.
- **Refresco**:
  - Deslizar hacia abajo recarga.
  - Mientras haya algún audio `PENDING` visible o un resumen en curso, recarga sola cada 10 s, solo con la app en primer plano y la pestaña del Diario visible.
  - También recarga al volver a la app.
  - Si una recarga falla, se mantienen los datos y se avisa arriba.
- **Barra de navegación inferior** con Diario, Historial, Buscar y Más. De momento solo el Diario tiene contenido; las demás muestran que llegan en una próxima versión.
- **App en español**: textos de Material (diálogos, accesibilidad) y fechas con `flutter_localizations` e `intl`.
- Fuera de esta fase: reproducir el audio (fase 4) y editar, eliminar, reintentar o generar el resumen (fase 6).

## Capabilities

### New Capabilities

- `diary`: portada del Diario de hoy (cifras, resumen, filtro, entradas) y su refresco.

### Modified Capabilities

- `app-shell`: navegación principal con barra inferior de cuatro secciones, y app localizada en español.

## Impact

- Dependencias: `flutter_localizations` (SDK) e `intl` (publisher dart.dev, la que usa el propio Flutter).
- Código: modelo `Diary` (respuesta de `/diario`, con `Streak`, `Week` y `TopTopic`), `lib/diary/` (provider y pantalla), `lib/format.dart` (fechas, horas y duraciones), `router.dart` (`StatefulShellRoute` con las cuatro pestañas), `home_screen.dart` (barra inferior), `app.dart` (idioma).
- Sin cambios en el backend.

# history Specification

## Purpose
TBD - created by archiving change history. Update Purpose after archive.
## Requirements
### Requirement: Calendario del mes
La sección Historial SHALL mostrar el calendario de un mes (de lunes a domingo) con los datos de `GET /api/v1/historial?month=AAAA-MM`; al entrar, el mes actual. Cada día con actividad SHALL mostrar el nº de notas en una pastilla de color (si tiene alguna) y un punto si tiene resumen. El día de hoy SHALL ir marcado.

#### Scenario: Días con actividad
- **WHEN** el usuario abre el Historial y el mes tiene el día 14 con 3 notas y resumen
- **THEN** el día 14 muestra «3» en la pastilla y el punto de resumen, y los días sin notas no muestran marca

#### Scenario: Resumen sin notas
- **WHEN** un día tiene resumen y `audio_count` 0
- **THEN** muestra solo el punto, sin pastilla

#### Scenario: Error al cargar
- **WHEN** la petición del mes falla
- **THEN** se muestra el `message` del error con un botón «Reintentar»

### Requirement: Cambiar de mes
`‹` y `›`, y deslizar el calendario a los lados, SHALL llevar al mes anterior y al siguiente (`previous_month` y `next_month` de la respuesta). `›` SHALL estar desactivado en el mes actual.

#### Scenario: Mes anterior
- **WHEN** el usuario pulsa «Mes anterior» en octubre de 2026
- **THEN** se pide `month=2026-09` y se muestra septiembre de 2026

#### Scenario: No pasar del mes actual
- **WHEN** se muestra el mes actual
- **THEN** «Mes siguiente» está desactivado

### Requirement: Detalle de un día
Tocar un día con actividad SHALL abrir su pantalla (`/historial/AAAA-MM-DD`) con los datos de `GET /api/v1/historial/{fecha}`: la fecha con el año, el nº de audios, el resumen (o «Sin resumen de este día.»), el filtro por estado y las notas con su transcripción, estado y botón «Escuchar». Los días sin actividad MUST NOT abrir nada. Volver SHALL dejar el calendario en el mismo mes. Deslizar hacia abajo SHALL recargar el día.

#### Scenario: Abrir un día
- **WHEN** el usuario toca el día 14
- **THEN** se pide `GET /api/v1/historial/2026-10-14` y se muestran su resumen y sus notas

#### Scenario: Filtrar
- **WHEN** en la pantalla del día el usuario elige «Error»
- **THEN** se pide el día con `status=ERROR`

#### Scenario: Escuchar desde el historial
- **WHEN** el usuario pulsa «Escuchar» en una nota del día
- **THEN** se reproduce igual que desde el Diario

### Requirement: Saltar al día con notas anterior o siguiente
La pantalla del día SHALL tener, a los lados de la fecha, un botón «Día anterior con notas» y otro «Día siguiente con notas» que abren el día de `previous_date` y `next_date` de `GET /api/v1/historial/{fecha}`, saltando los días vacíos. Si el campo es `null` (o el backend todavía no lo envía), el botón SHALL estar desactivado.

#### Scenario: Saltar hacia atrás
- **WHEN** en el día 2026-10-14 con `previous_date` `2026-10-13` el usuario pulsa «Día anterior con notas»
- **THEN** se abre el día 13 y volver lleva al calendario

#### Scenario: Sin más días
- **WHEN** `next_date` es `null`
- **THEN** «Día siguiente con notas» está desactivado


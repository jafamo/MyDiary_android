## ADDED Requirements

### Requirement: Lista de resúmenes
La pantalla Resúmenes SHALL mostrar los resúmenes de `GET /api/v1/resumenes` del más reciente al más antiguo. Cada uno SHALL mostrar la fecha con el año, el nº de audios del día y, plegado, las tres primeras líneas del texto. Sin resúmenes SHALL indicarlo. Deslizar hacia abajo SHALL recargar desde la primera página.

#### Scenario: Abrir la lista
- **WHEN** el usuario pulsa «Resúmenes» en «Más»
- **THEN** se pide `GET /api/v1/resumenes` y se ven los resúmenes con su fecha y su nº de audios

#### Scenario: Sin resúmenes
- **WHEN** la respuesta no trae ninguno
- **THEN** se muestra «Todavía no hay resúmenes.»

#### Scenario: Error al cargar
- **WHEN** la primera página falla
- **THEN** se muestra el `message` del error con un botón «Reintentar»

### Requirement: Desplegar un resumen
Tocar un resumen SHALL desplegarlo con el texto completo, la leyenda de emojis, los temas y las métricas de la IA (modelo, tokens y tiempo de generación, con «—» si faltan). Volver a tocarlo SHALL plegarlo.

#### Scenario: Desplegar
- **WHEN** el usuario toca un resumen plegado
- **THEN** se ven su leyenda, sus temas y sus métricas

#### Scenario: Resumen antiguo sin métricas
- **WHEN** un resumen desplegado no tiene modelo ni tokens
- **THEN** las métricas muestran «—»

### Requirement: Abrir el día
El chip con el nº de audios SHALL abrir ese día en el Historial (`/historial/AAAA-MM-DD`).

#### Scenario: Ir al día
- **WHEN** el usuario pulsa «3 audios» en el resumen del 14/10/2026
- **THEN** se abre la pantalla del día 14/10/2026 del Historial

### Requirement: Cargar más al llegar al final
La lista SHALL pedir la página siguiente al llegar al final mientras queden resúmenes (`page * per_page < total`). Si la petición falla, SHALL mantener lo cargado y mostrar al final el error con «Reintentar».

#### Scenario: Página siguiente
- **WHEN** hay 25 resúmenes y el usuario baja hasta el final de los 20 primeros
- **THEN** se pide `page=2` y se añaden los 5 restantes

#### Scenario: Falla la página siguiente
- **WHEN** la petición de `page=2` falla
- **THEN** siguen los 20 primeros y al final aparece el error con «Reintentar»

### Requirement: Filtrar por fechas
El botón «Filtrar por fechas» SHALL abrir un selector de rango de días hasta hoy. El rango elegido SHALL enviarse como `from` y `to` y mostrarse en un chip que lo quita al pulsar ✕. Sin resúmenes en el rango SHALL indicarlo.

#### Scenario: Elegir un rango
- **WHEN** el usuario elige del 1 al 15 de marzo de 2026
- **THEN** se pide `from=2026-03-01&to=2026-03-15` y aparece el chip del rango

#### Scenario: Quitar el rango
- **WHEN** el usuario pulsa ✕ en el chip
- **THEN** se vuelve a pedir la lista sin `from` ni `to`

#### Scenario: Rango vacío
- **WHEN** no hay resúmenes en el rango
- **THEN** se muestra «Sin resúmenes en estas fechas.»

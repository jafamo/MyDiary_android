## ADDED Requirements

### Requirement: Portada del Diario
La pestaña Diario SHALL mostrar los datos de `GET /api/v1/diario`:
- la fecha de hoy tal como la da el backend, sin conversión de zona, y el número de audios;
- la racha actual y la mejor;
- los audios de la semana con la diferencia respecto a la anterior;
- el tema del mes, o un guion si no hay.

#### Scenario: Cifras de la portada
- **WHEN** el backend devuelve `date` `2026-10-14`, racha 4 (mejor 12), semana 9 (delta 2) y tema `trabajo` con 6 menciones
- **THEN** la portada muestra «Miércoles, 14 de octubre», «4 días», «mejor: 12», «9 esta semana», «+2 vs. anterior», «trabajo» y «6 menciones»

#### Scenario: Sin tema del mes
- **WHEN** `top_topic` es `null`
- **THEN** en lugar del tema se muestra «—» y «sin resúmenes este mes»

### Requirement: Resumen del día
La portada SHALL mostrar el resumen de hoy en una tarjeta plegable, con la hora local de generación, el texto, la leyenda de emojis y los temas. Si la última generación está en curso (`QUEUED`/`RUNNING`), SHALL indicarlo. Si ha fallado, SHALL indicarlo con la hora. Sin resumen ni generación, SHALL indicar que todavía no hay resumen.

#### Scenario: Con resumen
- **WHEN** `summary` tiene texto, leyenda y temas
- **THEN** se muestran el texto, cada emoji con su significado y un chip por tema

#### Scenario: Generación en curso
- **WHEN** `summary_generation.status` es `RUNNING`
- **THEN** se muestra «Generando el resumen…»

#### Scenario: Sin resumen
- **WHEN** `summary` y `summary_generation` son `null`
- **THEN** se muestra «Todavía no hay resumen de hoy.»

### Requirement: Entradas del día
La portada SHALL listar las entradas en el orden del backend, con la hora local de recepción, la duración (`m:ss`) y el estado. Las transcritas SHALL mostrar el texto, plegado con «Ver más» si es largo. Las pendientes SHALL indicar que la transcripción está en curso. Las de error SHALL mostrar `error_message`. Sin entradas, SHALL indicar que no hay audios.

#### Scenario: Entrada transcrita
- **WHEN** una entrada `TRANSCRIBED` dura 37 s
- **THEN** se muestra «0:37», «Transcrito» y el texto de la transcripción

#### Scenario: Entrada con error
- **WHEN** una entrada está en `ERROR` con un `error_message`
- **THEN** se muestra «Error» y el mensaje

#### Scenario: Sin audios
- **WHEN** `entries` está vacío y no hay filtro
- **THEN** se muestra «Sin audios hoy.»

### Requirement: Filtro por estado
La portada SHALL ofrecer los filtros Todos, Pendiente, Transcrito y Error. Al elegir uno distinto de Todos, SHALL pedir `/diario` con `status` (`PENDING`, `TRANSCRIBED` o `ERROR`). Mientras carga, SHALL seguir mostrando los datos anteriores.

#### Scenario: Filtrar por error
- **WHEN** el usuario elige «Error»
- **THEN** se pide `GET /api/v1/diario?status=ERROR` y se muestran solo esas entradas

### Requirement: Refresco del Diario
Deslizar hacia abajo SHALL recargar el Diario. Mientras los datos visibles tengan algún audio `PENDING` o una generación del resumen en curso, la app SHALL recargarlo cada 10 s, solo si está en primer plano y con la pestaña del Diario visible. Al volver a primer plano, SHALL recargarlo. Si una recarga falla, SHALL mantener los datos y avisar arriba. Si falla la primera carga, SHALL mostrar el error con un botón para reintentar.

#### Scenario: Audio pendiente que se transcribe
- **WHEN** hay una entrada `PENDING` y pasan 10 s
- **THEN** se vuelve a pedir `/diario` y se muestra la entrada ya transcrita

#### Scenario: Nada pendiente
- **WHEN** ninguna entrada está `PENDING` ni hay un resumen en curso
- **THEN** no se hacen peticiones automáticas

#### Scenario: Recarga fallida con datos
- **WHEN** una recarga falla por falta de red
- **THEN** se siguen mostrando las entradas y aparece «No se pudo actualizar.»

#### Scenario: Primera carga fallida
- **WHEN** la primera petición a `/diario` falla
- **THEN** se muestra el mensaje de error y un botón «Reintentar» que vuelve a pedirlo

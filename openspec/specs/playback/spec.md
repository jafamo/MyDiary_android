# playback Specification

## Purpose
Escuchar las notas desde la app: descarga con el token, reproductor con salto y velocidad, reproducción en segundo plano y limpieza del fichero descargado.
## Requirements
### Requirement: Escuchar una nota
Cada entrada del Diario SHALL tener un botón «Escuchar», en cualquier estado del audio. Al pulsarlo, la app SHALL descargar el fichero con `GET /api/v1/audios/{id}/fichero` (con el token) a un fichero temporal, mostrando el progreso en el botón, y SHALL reproducirlo. La app MUST NOT pasar el token al reproductor ni usar un proxy HTTP local.

#### Scenario: Reproducir
- **WHEN** el usuario pulsa «Escuchar» en una entrada
- **THEN** se descarga su fichero, empieza a sonar y el botón pasa a «Pausa»

#### Scenario: Cancelar la descarga
- **WHEN** el usuario pulsa el botón mientras se descarga
- **THEN** la descarga se cancela, no suena nada y no se muestra ningún error

#### Scenario: El audio ya no existe
- **WHEN** la descarga responde `404`
- **THEN** se muestra el `message` del backend en un aviso y la entrada vuelve a «Escuchar»

### Requirement: Controles del reproductor
Mientras una nota suena o está en pausa, su tarjeta SHALL mostrar una barra de progreso que permite saltar, la posición y la duración (`0:05 / 0:14`) y la velocidad, que alterna entre 1×, 1,5× y 2×. Pulsar el botón SHALL pausar o continuar.

#### Scenario: Saltar
- **WHEN** el usuario suelta la barra en la mitad
- **THEN** la reproducción sigue desde la mitad del audio

#### Scenario: Velocidad
- **WHEN** el usuario pulsa `1×`
- **THEN** la velocidad pasa a 1,5× y el botón muestra `1,5×`

### Requirement: Un audio cada vez
Solo SHALL sonar una nota a la vez. Pulsar «Escuchar» en otra SHALL parar la actual, borrar su fichero y reproducir la nueva.

#### Scenario: Cambiar de nota
- **WHEN** suena una nota y el usuario pulsa «Escuchar» en otra
- **THEN** la primera se para, su tarjeta vuelve a «Escuchar», su fichero se borra y suena la segunda

### Requirement: Fichero temporal
El fichero descargado SHALL borrarse al terminar: cuando el audio acaba, cuando se para y cuando se pasa a otro. Los que queden de una sesión anterior SHALL borrarse antes de la siguiente descarga.

#### Scenario: Fin del audio
- **WHEN** el audio llega al final
- **THEN** su fichero se borra y la tarjeta vuelve a «Escuchar»

#### Scenario: Restos de otra sesión
- **WHEN** hay un fichero de escucha de una sesión anterior y se pide escuchar una nota
- **THEN** ese fichero se borra

### Requirement: Segundo plano
La reproducción SHALL seguir al salir de la app o con la pantalla apagada, con controles en la notificación y en la pantalla de bloqueo: título «Nota del <dd/mm> <HH:mm>» (hora local), reproducir/pausa, salto y parar. Parar desde la notificación SHALL equivaler a parar desde la app.

#### Scenario: Salir de la app
- **WHEN** suena una nota y el usuario sale de la app
- **THEN** sigue sonando y la notificación muestra sus controles

#### Scenario: Parar desde la notificación
- **WHEN** el usuario pulsa parar en la notificación
- **THEN** el audio se para, su fichero se borra y, al volver a la app, la tarjeta muestra «Escuchar»

### Requirement: Grabar pausa la escucha
Empezar a grabar una nota SHALL pausar la que esté sonando.

#### Scenario: Grabar mientras suena
- **WHEN** suena una nota y el usuario pulsa «Grabar nota»
- **THEN** la nota que sonaba queda en pausa


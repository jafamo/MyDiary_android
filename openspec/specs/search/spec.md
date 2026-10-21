# search Specification

## Purpose
TBD - created by archiving change search. Update Purpose after archive.
## Requirements
### Requirement: Buscar en el diario
La sección Buscar SHALL tener un campo de texto y SHALL buscar con `GET /api/v1/busqueda?q=` al enviar la consulta, no mientras se escribe. La consulta SHALL recortarse y, si queda vacía, no SHALL hacerse ninguna petición. Antes de la primera búsqueda SHALL mostrarse un texto de ayuda. Mientras se busca SHALL verse un indicador de carga; si la petición falla, SHALL mostrarse el `message` del error con «Reintentar». La app no SHALL guardar las búsquedas en el dispositivo. La última búsqueda SHALL conservarse al cambiar de sección.

#### Scenario: Buscar
- **WHEN** el usuario escribe « dentista » y pulsa la lupa del teclado
- **THEN** se pide `GET /api/v1/busqueda?q=dentista` y se muestran los resultados

#### Scenario: Consulta vacía
- **WHEN** el usuario envía el campo vacío o solo con espacios
- **THEN** no se hace ninguna petición

#### Scenario: Sin resultados
- **WHEN** la búsqueda no devuelve resultados ni recordatorios
- **THEN** se muestra «Sin resultados para «dentista».»

#### Scenario: Error
- **WHEN** la búsqueda falla
- **THEN** se muestra el mensaje de error y «Reintentar» repite la búsqueda

### Requirement: Resultados de la búsqueda
Los recordatorios que coinciden SHALL aparecer primero, con su fecha, su hora (si la tiene) y su texto. Después SHALL aparecer las notas y los resúmenes en el orden que da la API. Cada nota SHALL mostrarse con la tarjeta del Diario (▶, fecha, hora, duración, estado y texto plegable). Cada resumen SHALL mostrar su fecha y su texto plegado, y al desplegarse, la leyenda de emojis y los temas. Las notas y los resúmenes SHALL tener «Ver día», que abre ese día en el Historial. Un resultado de un tipo desconocido SHALL ignorarse.

#### Scenario: Orden de las secciones
- **WHEN** la búsqueda devuelve un recordatorio, una nota y un resumen
- **THEN** se ve primero el recordatorio y después la nota y el resumen en el orden de la API

#### Scenario: Escuchar una nota encontrada
- **WHEN** el usuario pulsa ▶ en una nota de los resultados
- **THEN** la nota se reproduce como en el Diario

#### Scenario: Abrir el día
- **WHEN** el usuario pulsa «Ver día» en un resultado del 2026-10-05
- **THEN** se abre `/historial/2026-10-05`


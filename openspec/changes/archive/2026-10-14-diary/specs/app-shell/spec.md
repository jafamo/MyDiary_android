## ADDED Requirements

### Requirement: Navegación principal
Con sesión, la app SHALL mostrar una barra de navegación inferior con cuatro secciones: Diario (`/`), Historial (`/historial`), Buscar (`/buscar`) y Más (`/mas`). Al cambiar de sección, cada una SHALL conservar su estado. Las secciones aún sin contenido SHALL indicar que llegan en una próxima versión.

#### Scenario: Inicio en el Diario
- **WHEN** la app arranca con sesión
- **THEN** se muestra la sección Diario con la barra inferior

#### Scenario: Cambiar de sección
- **WHEN** el usuario pulsa «Historial» en la barra inferior
- **THEN** se muestra la sección Historial con «Llega en una próxima versión.»

### Requirement: Idioma
La app SHALL estar en español, incluidos los textos propios de Material (diálogos, accesibilidad) y el formato de fechas.

#### Scenario: Fecha en español
- **WHEN** se muestra el día 2026-10-14
- **THEN** aparece como «miércoles, 14 de octubre»

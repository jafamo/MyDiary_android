## MODIFIED Requirements

### Requirement: Navegación principal
Con sesión, la app SHALL mostrar una barra de navegación inferior con cuatro secciones: Diario (`/`), Historial (`/historial`), Buscar (`/buscar`) y Más (`/mas`). Al cambiar de sección, cada una SHALL conservar su estado. «Más» SHALL ser un menú con Resúmenes, Recordatorios, Estadísticas y Categorías (los `Topic` de la API, con el mismo nombre que en la web); las que aún no tienen pantalla SHALL aparecer desactivadas como «Próximamente».

#### Scenario: Inicio en el Diario
- **WHEN** la app arranca con sesión
- **THEN** se muestra la sección Diario con la barra inferior

#### Scenario: Cambiar de sección
- **WHEN** el usuario pulsa «Buscar» en la barra inferior
- **THEN** se muestra la sección Buscar con su campo de búsqueda

#### Scenario: Menú Más
- **WHEN** el usuario pulsa «Más» en la barra inferior
- **THEN** «Resúmenes» se puede abrir y Recordatorios, Estadísticas y Categorías aparecen como «Próximamente»

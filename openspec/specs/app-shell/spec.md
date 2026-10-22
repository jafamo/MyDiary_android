# app-shell Specification

## Purpose
Arranque de la app: configuración de compilación obligatoria, idioma, navegación principal con barra inferior y redirección al login según la sesión.
## Requirements
### Requirement: Configuración obligatoria al arrancar
La app SHALL leer `API_BASE_URL` de la configuración de compilación. Si falta o no es una URL `http`/`https`, SHALL mostrar una pantalla de error de configuración que nombre la clave, sin intentar ninguna petición.

#### Scenario: Sin URL configurada
- **WHEN** la app se compila sin `API_BASE_URL`
- **THEN** al abrirla se muestra un error de configuración que menciona `API_BASE_URL`

#### Scenario: URL válida
- **WHEN** `API_BASE_URL` es `http://10.0.2.2:9008`
- **THEN** la app arranca con normalidad

### Requirement: Redirección al login
La navegación SHALL tener una ruta `/splash` (comprobando la sesión), una ruta `/login` y una ruta `/` (inicio), y SHALL decidir según el estado de la sesión: mientras se comprueba, `/splash`; sin sesión, cualquier ruta distinta de `/login` SHALL redirigir a `/login`; con sesión, `/login` y `/splash` SHALL redirigir a `/`. Cuando la sesión desaparece (logout o sesión caducada), la app SHALL volver a `/login` sin intervención del usuario.

#### Scenario: Comprobando la sesión
- **WHEN** la app arranca y la sesión aún no se ha comprobado
- **THEN** se muestra la pantalla de carga

#### Scenario: Arranque sin sesión
- **WHEN** la app arranca sin sesión guardada
- **THEN** se muestra la pantalla de login

#### Scenario: Arranque con sesión
- **WHEN** la app arranca con una sesión válida
- **THEN** se muestra la pantalla de inicio

#### Scenario: Sesión caducada
- **WHEN** con la pantalla de inicio visible la sesión se borra
- **THEN** se muestra la pantalla de login

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

### Requirement: Idioma
La app SHALL estar en español, incluidos los textos propios de Material (diálogos, accesibilidad) y el formato de fechas.

#### Scenario: Fecha en español
- **WHEN** se muestra el día 2026-10-14
- **THEN** aparece como «miércoles, 14 de octubre»


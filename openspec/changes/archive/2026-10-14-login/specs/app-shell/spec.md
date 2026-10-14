## MODIFIED Requirements

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

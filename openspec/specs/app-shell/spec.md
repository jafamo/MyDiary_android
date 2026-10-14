# app-shell Specification

## Purpose
Arranque de la app: configuración de compilación obligatoria y navegación con redirección al login según el token.
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
La navegación SHALL tener una ruta `/login` y una ruta `/` (inicio). Sin token, cualquier ruta distinta de `/login` SHALL redirigir a `/login`. Con token, `/login` SHALL redirigir a `/`. Cuando el token desaparece (logout o sesión caducada), la app SHALL volver a `/login` sin intervención del usuario.

#### Scenario: Arranque sin sesión
- **WHEN** la app arranca sin token
- **THEN** se muestra la pantalla de login

#### Scenario: Arranque con sesión
- **WHEN** la app arranca con token
- **THEN** se muestra la pantalla de inicio

#### Scenario: Sesión caducada
- **WHEN** con la pantalla de inicio visible el token se borra
- **THEN** se muestra la pantalla de login


## ADDED Requirements

### Requirement: Temas visuales de la web
La app SHALL definir los dos temas claros de la web, Moderno (`moderno`) y Cuaderno (`cuaderno`), con los tokens de `public/css/app.css` del backend: colores de fondo, panel, texto, acento, enlace y estados, fuentes de títulos, texto y cifras, y radios. La maqueta de las pantallas SHALL ser la misma en los dos temas. La app no SHALL tener modo oscuro. Mientras la API no exponga la preferencia del usuario, la app SHALL usar Moderno.

#### Scenario: Moderno por defecto
- **WHEN** la app arranca
- **THEN** el acento es `#0E7490`, el fondo `#F0F6F7` y el texto usa Plus Jakarta Sans

#### Scenario: Tokens de Cuaderno
- **WHEN** se construye el tema Cuaderno
- **THEN** el acento es `#92400E`, el fondo `#FFFBEB`, los títulos usan Newsreader y el texto Roboto

### Requirement: Fuentes incluidas
Las fuentes de los temas SHALL ir dentro de la app (las mismas familias, pesos y subconjunto que la web) y no SHALL descargarse en tiempo de ejecución. Sus licencias SHALL aparecer en la página de licencias de la app.

#### Scenario: Licencias
- **WHEN** se abre la página de licencias
- **THEN** aparecen Plus Jakarta Sans, JetBrains Mono, Newsreader y Roboto

### Requirement: Estado de las notas
El estado de cada nota SHALL mostrarse en una pastilla con el color de estado del tema y su fondo: pendiente, transcrito o error. Las horas, duraciones, métricas e indicadores SHALL usar la fuente de cifras del tema.

#### Scenario: Nota con error
- **WHEN** se muestra una nota en `ERROR` con el tema Moderno
- **THEN** su pastilla dice «Error» en `#B91C1C` sobre `#FEE2E2`

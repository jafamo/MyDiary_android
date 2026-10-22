## Why

La web de MyDiary estrenó el 20/10/2026 dos temas visuales, Moderno (por defecto) y Cuaderno (capability `ui-themes` del backend), con sus paletas, fuentes y radios. La app sigue con el verde azulado `#14968A`, que la web ya no usa. Además, la web llama ahora «Categorías» a los `Topic` (change `rename-topics-to-categories` del backend) para no confundirlos con el tema visual.

## What Changes

- **Tokens de los dos temas de la web en la app** (decisión del usuario: colores, fuentes y bordes; la maqueta de las pantallas es la misma en los dos). Son los de `public/css/app.css` del backend: fondo, panel, texto, acento, enlaces, colores de estado, fuente de títulos, de texto y de cifras, y radios.
  - Moderno: cian `#0E7490`, Plus Jakarta Sans y JetBrains Mono para horas y cifras.
  - Cuaderno: papel con marrón `#92400E` y violeta, Newsreader (títulos y texto de las notas) y Roboto.
  - Solo temas claros, como la web: sin modo oscuro.
- **Fuentes incluidas en la app**: las mismas de la web (subconjunto latin y mismos pesos), convertidas de `woff2` a TTF, con sus licencias OFL en la página de licencias. Sin descargas en tiempo de ejecución.
- **Estado de las notas en pastilla** con los colores de estado de la web (pendiente ámbar, transcrito verde, error rojo).
- **De momento la app usa siempre Moderno.** El selector y la preferencia compartida con la web (`ui_theme` del usuario) llegarán en otro change, cuando la API la exponga (decisión del usuario: preferencia en el backend).
- **Icono** con el fondo cian de Moderno (`#0E7490`), también en el icono y el gráfico de la ficha de Play.
- **«Categorías»**: la entrada «Temas» de «Más» pasa a llamarse «Categorías», como en la web.

## Capabilities

### New Capabilities

- `ui-themes`: temas visuales Moderno y Cuaderno con los tokens de la web.

### Modified Capabilities

- `app-shell`: «Más» lista «Categorías» en lugar de «Temas».

## Impact

- Código: `lib/theme/` (temas y extensión con los tokens que no tiene Material), `lib/app.dart`, `lib/main.dart` (licencias), las tarjetas de nota y la portada (cifras y pastilla de estado), `more_screen.dart`.
- `assets/fonts/` (10 TTF, unos 450 KB, y 4 licencias) y `pubspec.yaml`.
- Icono: `doc/icon/*.svg` y PNG regenerados, `ic_launcher_background.xml`.
- Sin dependencias nuevas ni cambios en el backend.

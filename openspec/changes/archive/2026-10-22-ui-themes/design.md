## Context

Los temas de la web son tokens CSS por `data-theme` (`moderno` / `cuaderno`). Además de los colores, Cuaderno cambia la maqueta (línea de tiempo en el Diario, pastilla de «Transcrito» oculta), que aquí queda fuera. Las fuentes de la web son `woff2`, que Flutter no admite.

## Decisions

- **`UiTheme` como enum con sus tokens** (`lib/theme/ui_theme.dart`), con los mismos valores (`moderno`, `cuaderno`) que el enum del backend, para que la preferencia de la API se lea tal cual en el siguiente change.
- **Tokens a Material 3**: el `ColorScheme` sale de `fromSeed(accent)` y se fijan encima los tokens que tienen equivalente: `primary` = acento, `primaryContainer` = acento suave, `secondary` = acento de contraste, `tertiary` = enlaces, `surface` = fondo, contenedores = panel y panel 2, `onSurfaceVariant` = texto atenuado, `outlineVariant` = borde y error con su fondo.
- **Lo que Material no tiene** (colores de estado con su fondo, enlace, estilo de las cifras y del texto de las notas) va en una `ThemeExtension` (`DiaryStyle`). Los widgets la leen con `DiaryStyle.of(context)` y no conocen el tema elegido.
- **Fuentes como assets**: los `woff2` de `public/fonts/` del backend se convierten a TTF con fontTools (`TTFont(...).flavor = None`), sin cambiar el subconjunto ni los pesos. Así la app y la web pintan los mismos glifos. Las licencias OFL se registran en `LicenseRegistry`. Se descarta `google_fonts`: descarga las fuentes en tiempo de ejecución desde Google.
- **Sin estado del tema elegido todavía**: `MyDiaryApp` construye Moderno. El provider de la preferencia llegará con el change que la lea de la API, cuando haga falta.

## Risks / Trade-offs

- Si la web cambia un token, la app no se entera: hay que copiarlo a mano. `lib/theme/ui_theme.dart` cita el fichero de origen para que sea fácil compararlos.

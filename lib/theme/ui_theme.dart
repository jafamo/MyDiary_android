import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Temas visuales de la web (enum `UiTheme` del backend, mismos valores). Los tokens son los
/// de `public/css/app.css` del backend: si cambian allí, se copian aquí a mano.
enum UiTheme {
  moderno(
    'Moderno',
    ThemeTokens(
      bg: Color(0xFFF0F6F7),
      panel: Color(0xFFFFFFFF),
      panel2: Color(0xFFE3EEF1),
      text: Color(0xFF0F2A33),
      textMuted: Color(0xFF4A6670),
      border: Color(0xFFD3E3E8),
      accent: Color(0xFF0E7490),
      accentContrast: Color(0xFFFFFFFF),
      accentSoft: Color(0xFFA5D4DF),
      accentDusk: Color(0xFFB45309),
      link: Color(0xFF0E7490),
      statusPending: Color(0xFF92400E),
      statusPendingBg: Color(0xFFFEF3C7),
      statusTranscribed: Color(0xFF065F46),
      statusTranscribedBg: Color(0xFFD1FAE5),
      statusError: Color(0xFFB91C1C),
      statusErrorBg: Color(0xFFFEE2E2),
      headingFont: Fonts.plusJakartaSans,
      bodyFont: Fonts.plusJakartaSans,
      displayFont: Fonts.jetBrainsMono,
      radius: 12,
      radiusLg: 18,
      barsOnPanel2: false,
    ),
  ),
  cuaderno(
    'Cuaderno',
    ThemeTokens(
      bg: Color(0xFFFFFBEB),
      panel: Color(0xFFFFFFFF),
      panel2: Color(0xFFF8F3F0),
      text: Color(0xFF0F172A),
      textMuted: Color(0xFF475569),
      border: Color(0xFFE9DDD3),
      accent: Color(0xFF92400E),
      accentContrast: Color(0xFFFFFFFF),
      accentSoft: Color(0xFFE9C9A8),
      accentDusk: Color(0xFF4F46E5),
      link: Color(0xFF4F46E5),
      statusPending: Color(0xFFB45309),
      statusPendingBg: Color(0xFFFEF3C7),
      statusTranscribed: Color(0xFF047857),
      statusTranscribedBg: Color(0xFFD1FAE5),
      statusError: Color(0xFFB91C1C),
      statusErrorBg: Color(0xFFFEE2E2),
      headingFont: Fonts.newsreader,
      bodyFont: Fonts.roboto,
      displayFont: Fonts.roboto,
      radius: 10,
      radiusLg: 16,
      barsOnPanel2: true,
      noteTextInHeadingFont: true,
    ),
  );

  const UiTheme(this.label, this.tokens);

  final String label;
  final ThemeTokens tokens;

  ThemeData get themeData => tokens.themeData();
}

/// Familias declaradas en `pubspec.yaml` (TTF convertidos de los `woff2` de la web).
abstract final class Fonts {
  static const plusJakartaSans = 'PlusJakartaSans';
  static const jetBrainsMono = 'JetBrainsMono';
  static const newsreader = 'Newsreader';
  static const roboto = 'Roboto';

  /// Nombre y fichero (`assets/fonts/<fichero>.LICENSE`) de cada familia, para las licencias.
  static const licenses = [
    ('Plus Jakarta Sans', 'plus-jakarta-sans'),
    ('JetBrains Mono', 'jetbrains-mono'),
    ('Newsreader', 'newsreader'),
    ('Roboto', 'roboto'),
  ];
}

/// Licencias OFL de las fuentes de los temas, para `LicenseRegistry`.
Stream<LicenseEntry> fontLicenses() async* {
  for (final (name, file) in Fonts.licenses) {
    yield LicenseEntryWithLineBreaks([
      name,
    ], await rootBundle.loadString('assets/fonts/$file.LICENSE'));
  }
}

/// Variables CSS de un tema (`--bg`, `--panel`... `--radius-lg`).
class ThemeTokens {
  const ThemeTokens({
    required this.bg,
    required this.panel,
    required this.panel2,
    required this.text,
    required this.textMuted,
    required this.border,
    required this.accent,
    required this.accentContrast,
    required this.accentSoft,
    required this.accentDusk,
    required this.link,
    required this.statusPending,
    required this.statusPendingBg,
    required this.statusTranscribed,
    required this.statusTranscribedBg,
    required this.statusError,
    required this.statusErrorBg,
    required this.headingFont,
    required this.bodyFont,
    required this.displayFont,
    required this.radius,
    required this.radiusLg,
    required this.barsOnPanel2,
    this.noteTextInHeadingFont = false,
  });

  final Color bg;
  final Color panel;
  final Color panel2;
  final Color text;
  final Color textMuted;
  final Color border;
  final Color accent;
  final Color accentContrast;
  final Color accentSoft;
  final Color accentDusk;
  final Color link;
  final Color statusPending;
  final Color statusPendingBg;
  final Color statusTranscribed;
  final Color statusTranscribedBg;
  final Color statusError;
  final Color statusErrorBg;

  /// Títulos, texto, y horas, cifras y etiquetas.
  final String headingFont;
  final String bodyFont;
  final String displayFont;

  final double radius;
  final double radiusLg;

  /// Barra superior e inferior sobre `--panel-2` (Cuaderno) en lugar de `--panel`.
  final bool barsOnPanel2;

  /// Texto de las notas con la fuente de títulos y algo mayor (Cuaderno).
  final bool noteTextInHeadingFont;

  ThemeData themeData() {
    final colors = ColorScheme.fromSeed(seedColor: accent).copyWith(
      primary: accent,
      onPrimary: accentContrast,
      primaryContainer: accentSoft,
      onPrimaryContainer: text,
      secondary: accentDusk,
      onSecondary: accentContrast,
      tertiary: link,
      onTertiary: accentContrast,
      surface: bg,
      onSurface: text,
      onSurfaceVariant: textMuted,
      surfaceContainerLowest: panel,
      surfaceContainerLow: panel,
      surfaceContainer: panel,
      surfaceContainerHigh: panel2,
      surfaceContainerHighest: panel2,
      outline: Color.lerp(border, textMuted, 0.5),
      outlineVariant: border,
      error: statusError,
      onError: accentContrast,
      errorContainer: statusErrorBg,
      onErrorContainer: statusError,
      surfaceTint: Colors.transparent,
    );
    final bars = barsOnPanel2 ? panel2 : panel;
    final base = Typography.material2021().black;
    final textTheme = base
        .apply(fontFamily: bodyFont, bodyColor: text, displayColor: text)
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(fontFamily: headingFont),
          displayMedium: base.displayMedium?.copyWith(fontFamily: headingFont),
          displaySmall: base.displaySmall?.copyWith(fontFamily: headingFont),
          headlineLarge: base.headlineLarge?.copyWith(fontFamily: headingFont),
          headlineMedium: base.headlineMedium?.copyWith(
            fontFamily: headingFont,
          ),
          headlineSmall: base.headlineSmall?.copyWith(fontFamily: headingFont),
          titleLarge: base.titleLarge?.copyWith(fontFamily: headingFont),
        )
        .apply(bodyColor: text, displayColor: text);

    return ThemeData(
      colorScheme: colors,
      scaffoldBackgroundColor: bg,
      fontFamily: bodyFont,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bars,
        foregroundColor: text,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: border)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bars,
        indicatorColor: accentSoft,
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 1,
        shadowColor: text.withValues(alpha: 0.25),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius / 2),
        ),
      ),
      dividerTheme: DividerThemeData(color: border),
      extensions: [
        DiaryStyle(
          statusPending: statusPending,
          statusPendingBg: statusPendingBg,
          statusTranscribed: statusTranscribed,
          statusTranscribedBg: statusTranscribedBg,
          statusError: statusError,
          statusErrorBg: statusErrorBg,
          link: link,
          figures: TextStyle(
            fontFamily: displayFont,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          noteText: noteTextInHeadingFont
              ? TextStyle(fontFamily: headingFont, fontSize: 18, height: 1.55)
              : const TextStyle(height: 1.6),
        ),
      ],
    );
  }
}

/// Tokens de la web sin equivalente en Material: colores de estado, enlace, cifras y texto
/// de las notas.
class DiaryStyle extends ThemeExtension<DiaryStyle> {
  const DiaryStyle({
    required this.statusPending,
    required this.statusPendingBg,
    required this.statusTranscribed,
    required this.statusTranscribedBg,
    required this.statusError,
    required this.statusErrorBg,
    required this.link,
    required this.figures,
    required this.noteText,
  });

  /// El del tema de la app; Moderno si el árbol no lo tiene (p. ej. en un test de widget suelto).
  static DiaryStyle of(BuildContext context) =>
      Theme.of(context).extension<DiaryStyle>() ??
      UiTheme.moderno.themeData.extension<DiaryStyle>()!;

  final Color statusPending;
  final Color statusPendingBg;
  final Color statusTranscribed;
  final Color statusTranscribedBg;
  final Color statusError;
  final Color statusErrorBg;
  final Color link;

  /// Horas, duraciones y cifras (`--font-display`), con cifras de ancho fijo.
  final TextStyle figures;

  /// Texto de una nota transcrita.
  final TextStyle noteText;

  @override
  DiaryStyle copyWith({
    Color? statusPending,
    Color? statusPendingBg,
    Color? statusTranscribed,
    Color? statusTranscribedBg,
    Color? statusError,
    Color? statusErrorBg,
    Color? link,
    TextStyle? figures,
    TextStyle? noteText,
  }) => DiaryStyle(
    statusPending: statusPending ?? this.statusPending,
    statusPendingBg: statusPendingBg ?? this.statusPendingBg,
    statusTranscribed: statusTranscribed ?? this.statusTranscribed,
    statusTranscribedBg: statusTranscribedBg ?? this.statusTranscribedBg,
    statusError: statusError ?? this.statusError,
    statusErrorBg: statusErrorBg ?? this.statusErrorBg,
    link: link ?? this.link,
    figures: figures ?? this.figures,
    noteText: noteText ?? this.noteText,
  );

  @override
  DiaryStyle lerp(DiaryStyle? other, double t) {
    if (other == null) return this;
    return DiaryStyle(
      statusPending: Color.lerp(statusPending, other.statusPending, t)!,
      statusPendingBg: Color.lerp(statusPendingBg, other.statusPendingBg, t)!,
      statusTranscribed: Color.lerp(
        statusTranscribed,
        other.statusTranscribed,
        t,
      )!,
      statusTranscribedBg: Color.lerp(
        statusTranscribedBg,
        other.statusTranscribedBg,
        t,
      )!,
      statusError: Color.lerp(statusError, other.statusError, t)!,
      statusErrorBg: Color.lerp(statusErrorBg, other.statusErrorBg, t)!,
      link: Color.lerp(link, other.link, t)!,
      figures: TextStyle.lerp(figures, other.figures, t)!,
      noteText: TextStyle.lerp(noteText, other.noteText, t)!,
    );
  }
}

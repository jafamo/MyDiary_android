import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mydiary/diary/entry_widgets.dart';
import 'package:mydiary/models/audio.dart';
import 'package:mydiary/theme/ui_theme.dart';

import '../fixtures.dart';
import '../support/app_harness.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  test('Moderno con los tokens de la web', () {
    final theme = UiTheme.moderno.themeData;
    final style = theme.extension<DiaryStyle>()!;

    expect(theme.colorScheme.primary, const Color(0xFF0E7490));
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF0F6F7));
    expect(theme.colorScheme.onSurface, const Color(0xFF0F2A33));
    expect(theme.textTheme.bodyMedium!.fontFamily, Fonts.plusJakartaSans);
    expect(theme.textTheme.titleLarge!.fontFamily, Fonts.plusJakartaSans);
    expect(style.figures.fontFamily, Fonts.jetBrainsMono);
    expect(style.noteText.fontFamily, isNull);
    expect(theme.appBarTheme.backgroundColor, Colors.white);
  });

  test('Cuaderno con los tokens de la web', () {
    final theme = UiTheme.cuaderno.themeData;
    final style = theme.extension<DiaryStyle>()!;

    expect(theme.colorScheme.primary, const Color(0xFF92400E));
    expect(theme.colorScheme.tertiary, const Color(0xFF4F46E5));
    expect(theme.scaffoldBackgroundColor, const Color(0xFFFFFBEB));
    expect(theme.textTheme.bodyMedium!.fontFamily, Fonts.roboto);
    expect(theme.textTheme.titleLarge!.fontFamily, Fonts.newsreader);
    expect(style.figures.fontFamily, Fonts.roboto);
    expect(style.noteText.fontFamily, Fonts.newsreader);
    expect(style.statusPending, const Color(0xFFB45309));
    expect(theme.appBarTheme.backgroundColor, const Color(0xFFF8F3F0));
  });

  test('licencias de las cuatro fuentes', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final entries = await fontLicenses().toList();

    expect(entries.expand((e) => e.packages), [
      'Plus Jakarta Sans',
      'JetBrains Mono',
      'Newsreader',
      'Roboto',
    ]);
    for (final entry in entries) {
      expect(
        entry.paragraphs.map((p) => p.text).join(' '),
        contains('SIL Open Font License'),
      );
    }
  });

  testWidgets('pastilla de error con los colores de estado de Moderno', (
    tester,
  ) async {
    final container = createTestContainer(
      backend: fakeBackend(),
      storage: MemoryTokenStorage(storedSession),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: UiTheme.moderno.themeData,
          home: Scaffold(
            body: EntryCard(audio: Audio.fromJson(fixture('audio_error'))),
          ),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('Error'));
    final pill = tester.widget<Container>(
      find
          .ancestor(of: find.text('Error'), matching: find.byType(Container))
          .first,
    );

    expect(label.style!.color, const Color(0xFFB91C1C));
    expect((pill.decoration! as BoxDecoration).color, const Color(0xFFFEE2E2));
  });
}

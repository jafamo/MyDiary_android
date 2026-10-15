import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary/api/json.dart';
import 'package:mydiary/app.dart';
import 'package:mydiary/diary/diary_screen.dart';
import 'package:mydiary/format.dart';

import '../fixtures.dart';
import '../support/app_harness.dart';
import '../support/fake_http.dart';

void main() {
  late FakeAdapter backend;

  setUp(() => backend = fakeBackend());

  Future<void> startApp(WidgetTester tester) async {
    // Pantalla alta para que la lista construya todas las entradas.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = createTestContainer(
      backend: backend,
      storage: MemoryTokenStorage(storedSession),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MyDiaryApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// El backend responde a `/diario` con [diary] y al resto como siempre.
  void serveDiary(Json diary) {
    final fallback = fakeBackend().handler;
    backend.handler = (options) => options.uri.path == '/api/v1/diario'
        ? jsonResponse(200, diary)
        : fallback(options);
  }

  int diaryCalls() =>
      backend.calls.where((c) => c == 'GET /api/v1/diario').length;

  Json diaryWith(Map<String, Object?> changes) => {
    ...fixture('diary'),
    ...changes,
  };

  /// Sin nada pendiente: no hay sondeo.
  Json settledDiary() => diaryWith({
    'entries': [
      for (final e in fixture('diary')['entries']! as List<Object?>)
        if (asJson(e)['status'] != 'PENDING') e,
    ],
  });

  Finder inEntries(String text) =>
      find.descendant(of: find.byType(Card), matching: find.text(text));

  testWidgets('cabecera y cifras', (tester) async {
    await startApp(tester);

    expect(find.text('Miércoles, 14 de octubre'), findsOneWidget);
    expect(find.text('3 audios'), findsOneWidget);
    expect(find.text('4 días'), findsOneWidget);
    expect(find.text('mejor: 12'), findsOneWidget);
    expect(find.text('9 esta semana'), findsOneWidget);
    expect(find.text('+2 vs. anterior'), findsOneWidget);
    expect(find.text('6 menciones'), findsOneWidget);
  });

  testWidgets('sin tema del mes y semana a la baja', (tester) async {
    serveDiary(
      diaryWith({
        'top_topic': null,
        'week': {'total': 3, 'delta': -2},
      }),
    );
    await startApp(tester);

    expect(find.text('—'), findsOneWidget);
    expect(find.text('sin resúmenes este mes'), findsOneWidget);
    expect(find.text('−2 vs. anterior'), findsOneWidget);
  });

  testWidgets('resumen del día con leyenda y temas', (tester) async {
    await startApp(tester);

    final generatedAt = formatTime(DateTime.utc(2026, 10, 14, 19, 40));
    expect(find.text('Resumen del día · $generatedAt'), findsOneWidget);
    expect(
      find.text('💼 Día de trabajo en el proyecto. 🦷 Visita al dentista.'),
      findsOneWidget,
    );
    expect(find.text('🦷 Dentista'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'salud'), findsOneWidget);
  });

  testWidgets('sin resumen', (tester) async {
    serveDiary(diaryWith({'summary': null}));
    await startApp(tester);

    expect(find.text('Todavía no hay resumen de hoy.'), findsOneWidget);
  });

  testWidgets('resumen generándose', (tester) async {
    serveDiary(
      diaryWith({
        'summary': null,
        'summary_generation': {
          ...fixture('summary_generation_stalled'),
          'status': 'RUNNING',
          'finished_at': null,
          'error_code': null,
          'error_message': null,
        },
      }),
    );
    await startApp(tester);

    expect(find.text('Generando el resumen…'), findsOneWidget);
    expect(find.text('Todavía no hay resumen de hoy.'), findsNothing);
  });

  testWidgets('entradas con su estado', (tester) async {
    await startApp(tester);

    expect(
      find.text('${formatTime(DateTime.utc(2026, 10, 14, 7, 12, 5))} · 0:37'),
      findsOneWidget,
    );
    expect(inEntries('Transcrito'), findsOneWidget);
    expect(
      find.text(
        'Esta mañana he ido al dentista y luego he trabajado en el proyecto.',
      ),
      findsOneWidget,
    );
    expect(inEntries('Transcribiendo…'), findsOneWidget);
    expect(find.text('Transcripción en curso…'), findsOneWidget);
    expect(find.text('Tiempo de transcripción agotado.'), findsOneWidget);
  });

  testWidgets('texto largo plegado con «Ver más»', (tester) async {
    final long = List.filled(40, 'Una frase bastante larga.').join(' ');
    final entries = fixture('diary')['entries']! as List<Object?>;
    serveDiary(
      diaryWith({
        'entries': [
          {
            ...asJson(entries.first),
            'transcription': {
              ...asJson(asJson(entries.first)['transcription']),
              'content': long,
            },
          },
        ],
      }),
    );
    await startApp(tester);

    expect(find.text('Ver más'), findsOneWidget);
    await tester.tap(find.text('Ver más'));
    await tester.pump();
    expect(find.text('Ver menos'), findsOneWidget);
  });

  testWidgets('sin audios', (tester) async {
    serveDiary(diaryWith({'entries': <Object?>[]}));
    await startApp(tester);

    expect(find.text('Sin audios hoy.'), findsOneWidget);
    expect(find.text('0 audios'), findsOneWidget);
  });

  testWidgets('el filtro pide el estado elegido', (tester) async {
    await startApp(tester);
    serveDiary(
      diaryWith({
        'entries': [
          for (final e in fixture('diary')['entries']! as List<Object?>)
            if (asJson(e)['status'] == 'ERROR') e,
        ],
      }),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Error'));
    await tester.pumpAndSettle();

    expect(backend.requests.last.uri.queryParameters, {'status': 'ERROR'});
    expect(find.text('1 audio'), findsOneWidget);
    expect(find.text('Transcripción en curso…'), findsNothing);
  });

  testWidgets('con un audio pendiente recarga hasta que se transcribe', (
    tester,
  ) async {
    await startApp(tester);
    expect(diaryCalls(), 1);
    serveDiary(settledDiary());

    await tester.pump(DiaryScreen.pollInterval);
    await tester.pumpAndSettle();
    expect(diaryCalls(), 2);
    expect(find.text('Transcripción en curso…'), findsNothing);

    await tester.pump(DiaryScreen.pollInterval * 3);
    expect(diaryCalls(), 2);
  });

  testWidgets('sin nada pendiente no recarga solo', (tester) async {
    serveDiary(settledDiary());
    await startApp(tester);

    await tester.pump(DiaryScreen.pollInterval * 3);

    expect(diaryCalls(), 1);
  });

  testWidgets('con la pestaña oculta no recarga', (tester) async {
    await startApp(tester);

    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.text('Llega en una próxima versión.'), findsOneWidget);

    await tester.pump(DiaryScreen.pollInterval * 2);
    expect(diaryCalls(), 1);

    await tester.tap(find.text('Diario'));
    await tester.pumpAndSettle();
    await tester.pump(DiaryScreen.pollInterval);
    await tester.pumpAndSettle();
    expect(diaryCalls(), 2);
  });

  testWidgets('deslizar hacia abajo recarga', (tester) async {
    serveDiary(settledDiary());
    await startApp(tester);

    await tester.fling(
      find.text('Miércoles, 14 de octubre'),
      const Offset(0, 1500),
      1000,
    );
    await tester.pumpAndSettle();

    expect(diaryCalls(), 2);
  });

  testWidgets('una recarga fallida mantiene los datos y avisa', (tester) async {
    await startApp(tester);
    backend.handler = networkDown;

    await tester.pump(DiaryScreen.pollInterval);
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo actualizar.'), findsOneWidget);
    expect(find.text('Miércoles, 14 de octubre'), findsOneWidget);
  });

  testWidgets('primera carga fallida con reintento', (tester) async {
    backend.handler = networkDown;
    await startApp(tester);

    expect(find.text('No se pudo conectar con el servidor.'), findsOneWidget);

    backend.handler = fakeBackend().handler;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Miércoles, 14 de octubre'), findsOneWidget);
  });
}

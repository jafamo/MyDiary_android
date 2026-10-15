import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary/api/json.dart';
import 'package:mydiary/app.dart';

import '../fixtures.dart';
import '../support/app_harness.dart';
import '../support/fake_http.dart';

void main() {
  late FakeAdapter backend;
  late ProviderContainer container;

  setUp(() => backend = fakeBackend());

  /// Arranca la app (hoy es el 14/10/2026, la fecha del Diario) y abre Más › Resúmenes.
  Future<void> openSummaries(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    container = createTestContainer(
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
    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resúmenes'));
    await tester.pumpAndSettle();
  }

  /// Desmonta la app para que no quede vivo el sondeo del Diario.
  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  }

  List<Map<String, Object?>> summaryRequests() => [
    for (final request in backend.requests)
      if (request.uri.path == '/api/v1/resumenes') request.uri.queryParameters,
  ];

  /// Responde a `/resumenes` con [total] resúmenes, de 20 en 20, del 14/10/2026 hacia atrás.
  void serveSummaries(int total, {bool failPage2 = false}) {
    final fallback = backend.handler;
    final base = asJson(
      (fixture('summaries_page')['items']! as List<Object?>).first,
    );
    backend.handler = (options) {
      if (options.uri.path != '/api/v1/resumenes') return fallback(options);
      final page = int.parse(options.uri.queryParameters['page']!);
      if (page == 2 && failPage2) {
        return apiError(500, 'internal_error', 'Error interno.');
      }
      final first = (page - 1) * 20;
      return jsonResponse(200, {
        'items': [
          for (var i = first; i < total && i < first + 20; i++)
            {
              ...base,
              'id': 100 + i,
              'date': DateTime(
                2026,
                10,
                14 - i,
              ).toIso8601String().substring(0, 10),
              'summary_text': 'Resumen número $i.',
            },
        ],
        'page': page,
        'per_page': 20,
        'total': total,
      });
    };
  }

  Future<void> scrollToEnd(WidgetTester tester) async {
    await tester.fling(find.byType(ListView), const Offset(0, -20000), 5000);
    await tester.pumpAndSettle();
  }

  testWidgets('«Más» abre Resúmenes y el resto sale como próximamente', (
    tester,
  ) async {
    await openSummaries(tester);

    expect(summaryRequests(), [
      {'page': '1'},
    ]);
    expect(find.text('Lun 5 oct 2026'), findsOneWidget);
    expect(find.text('3 audios'), findsOneWidget);
    expect(find.text('Dom 4 oct 2026'), findsOneWidget);
    expect(find.text('1 audio'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Próximamente'), findsNWidgets(3));

    await closeApp(tester);
  });

  testWidgets('desplegar muestra la leyenda, los temas y las métricas', (
    tester,
  ) async {
    await openSummaries(tester);
    expect(find.text('💼 Trabajo'), findsNothing);

    await tester.tap(find.text('Lun 5 oct 2026'));
    await tester.pumpAndSettle();

    expect(find.text('💼 Trabajo'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'salud'), findsOneWidget);
    expect(
      find.text('qwen2.5:7b · 3.412 tokens (2.980 + 432) · 38 s'),
      findsOneWidget,
    );

    await tester.tap(find.text('Dom 4 oct 2026'));
    await tester.pumpAndSettle();
    expect(find.text('— · — tokens (— + —) · —'), findsOneWidget);

    await tester.tap(find.text('Lun 5 oct 2026'));
    await tester.pumpAndSettle();
    expect(find.text('💼 Trabajo'), findsNothing);

    await closeApp(tester);
  });

  testWidgets('el chip de audios abre el día en el Historial', (tester) async {
    await openSummaries(tester);

    await tester.tap(find.text('3 audios'));
    await tester.pumpAndSettle();

    expect(backend.calls, contains('GET /api/v1/historial/2026-10-05'));
    expect(find.text('Lunes, 5 de octubre de 2026'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('al llegar al final carga la página siguiente', (tester) async {
    serveSummaries(25);
    await openSummaries(tester);
    expect(find.text('Resumen número 0.'), findsOneWidget);

    await scrollToEnd(tester);

    expect(summaryRequests().map((q) => q['page']), ['1', '2']);
    expect(find.text('Resumen número 24.'), findsOneWidget);

    await scrollToEnd(tester);
    expect(summaryRequests(), hasLength(2));

    await closeApp(tester);
  });

  testWidgets('si falla la página siguiente se mantiene lo cargado', (
    tester,
  ) async {
    serveSummaries(25, failPage2: true);
    await openSummaries(tester);

    await scrollToEnd(tester);

    expect(find.text('Error interno.'), findsOneWidget);
    expect(find.text('Resumen número 19.'), findsOneWidget);
    expect(summaryRequests(), hasLength(2));

    serveSummaries(25);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    await scrollToEnd(tester);

    expect(find.text('Resumen número 24.'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('error al cargar y reintentar', (tester) async {
    final respond = backend.handler;
    backend.handler = (options) => options.uri.path == '/api/v1/resumenes'
        ? apiError(500, 'internal_error', 'Error interno.')
        : respond(options);
    await openSummaries(tester);

    expect(find.text('Error interno.'), findsOneWidget);

    backend.handler = respond;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Lun 5 oct 2026'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('filtrar por fechas y quitar el filtro', (tester) async {
    serveSummaries(0);
    await openSummaries(tester);
    expect(find.text('Todavía no hay resúmenes.'), findsOneWidget);

    await tester.tap(find.byTooltip('Filtrar por fechas'));
    await tester.pumpAndSettle();
    // Entrada por texto del selector de rango.
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '01/03/2026');
    await tester.enterText(find.byType(TextField).at(1), '15/03/2026');
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();

    expect(summaryRequests().last, {
      'from': '2026-03-01',
      'to': '2026-03-15',
      'page': '1',
    });
    expect(find.text('1 mar – 15 mar 2026'), findsOneWidget);
    expect(find.text('Sin resúmenes en estas fechas.'), findsOneWidget);

    await tester.tap(find.byTooltip('Quitar el filtro'));
    await tester.pumpAndSettle();

    expect(summaryRequests().last, {'page': '1'});
    expect(find.text('1 mar – 15 mar 2026'), findsNothing);
    expect(find.text('Todavía no hay resúmenes.'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('deslizar hacia abajo recarga desde el principio', (
    tester,
  ) async {
    await openSummaries(tester);

    await tester.fling(
      find.text('Lun 5 oct 2026'),
      const Offset(0, 1500),
      1000,
    );
    await tester.pumpAndSettle();

    expect(summaryRequests(), hasLength(2));

    await closeApp(tester);
  });
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary/app.dart';
import 'package:mydiary/history/history_provider.dart';

import '../support/app_harness.dart';
import '../support/fake_http.dart';
import '../support/fake_player.dart';

void main() {
  late FakeAdapter backend;
  late FakePlayer player;
  late ProviderContainer container;

  setUp(() {
    backend = fakeBackend();
    player = FakePlayer();
  });

  /// Arranca la app (hoy es el 14/10/2026, la fecha del Diario) y abre el Historial.
  Future<void> openHistory(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final directory = Directory.systemTemp.createTempSync('mydiary-test-');
    addTearDown(() => directory.deleteSync(recursive: true));

    container = createTestContainer(
      backend: backend,
      storage: MemoryTokenStorage(storedSession),
      player: player,
      temporaryDirectory: directory,
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MyDiaryApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
  }

  /// Desmonta la app para que no quede vivo el sondeo del Diario.
  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  }

  /// Responde a `/historial?month=` con un mes sin más actividad que [days].
  void serveMonths({List<Map<String, Object?>> days = const []}) {
    final fallback = backend.handler;
    backend.handler = (options) {
      final month = options.queryParameters['month'] as String?;
      if (options.uri.path != '/api/v1/historial' || month == null) {
        return fallback(options);
      }
      final date = DateTime.parse('$month-01');
      String format(DateTime d) => formatMonthParam(d);
      return jsonResponse(200, {
        'month': month,
        'previous_month': format(DateTime(date.year, date.month - 1)),
        'next_month': format(DateTime(date.year, date.month + 1)),
        'days': [
          for (final day in days)
            if ((day['date']! as String).startsWith(month)) day,
        ],
      });
    };
  }

  Finder day(int month, int dayOfMonth) =>
      find.byKey(ValueKey(DateTime(2026, month, dayOfMonth)));

  Finder inDay(int month, int dayOfMonth, Finder finder) =>
      find.descendant(of: day(month, dayOfMonth), matching: finder);

  List<String> historyCalls() => [
    for (final r in backend.requests)
      if (r.uri.path.startsWith('/api/v1/historial')) r.uri.toString(),
  ];

  testWidgets('calendario con los días con notas', (tester) async {
    await openHistory(tester);

    expect(historyCalls().single, endsWith('/api/v1/historial'));
    expect(find.text('Octubre de 2026'), findsOneWidget);
    expect(inDay(10, 14, find.text('3')), findsOneWidget);
    expect(inDay(10, 14, find.byKey(const ValueKey('resumen'))), findsOne);
    expect(inDay(10, 13, find.text('12')), findsOneWidget);
    expect(inDay(10, 3, find.text('1')), findsOneWidget);
    expect(inDay(10, 3, find.byKey(const ValueKey('resumen'))), findsNothing);
    // Resumen sin notas: solo el punto.
    expect(inDay(10, 2, find.text('0')), findsNothing);
    expect(inDay(10, 2, find.byKey(const ValueKey('resumen'))), findsOne);
    expect(inDay(10, 5, find.text('5')), findsOneWidget);
    expect(inDay(10, 5, find.byType(Container)), findsOneWidget);
    // El 1 de octubre de 2026 es jueves: tres huecos antes.
    final monday = tester.getTopLeft(find.text('L')).dx;
    final thursday = tester.getTopLeft(find.text('J')).dx;
    expect(tester.getTopLeft(day(10, 1)).dx, thursday);
    expect(tester.getTopLeft(day(10, 5)).dx, monday);

    await closeApp(tester);
  });

  testWidgets('cambiar de mes con las flechas', (tester) async {
    serveMonths();
    await openHistory(tester);
    final next = find.ancestor(
      of: find.byTooltip('Mes siguiente'),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(next).onPressed, isNull);

    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();

    expect(historyCalls().last, endsWith('/api/v1/historial?month=2026-09'));
    expect(find.text('Septiembre de 2026'), findsOneWidget);
    expect(tester.widget<IconButton>(next).onPressed, isNotNull);

    await tester.tap(next);
    await tester.pumpAndSettle();

    expect(historyCalls().last, endsWith('/api/v1/historial?month=2026-10'));
    expect(find.text('Octubre de 2026'), findsOneWidget);
    expect(tester.widget<IconButton>(next).onPressed, isNull);

    await closeApp(tester);
  });

  testWidgets('cambiar de mes deslizando', (tester) async {
    serveMonths();
    await openHistory(tester);

    await tester.fling(day(10, 15), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Octubre de 2026'), findsOneWidget);

    await tester.fling(day(10, 15), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Septiembre de 2026'), findsOneWidget);

    await tester.fling(day(9, 15), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Octubre de 2026'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('error al cargar el mes y reintentar', (tester) async {
    final fallback = backend.handler;
    backend.handler = (options) => options.uri.path == '/api/v1/historial'
        ? apiError(500, 'internal_error', 'Error interno.')
        : fallback(options);
    await openHistory(tester);

    expect(find.text('Error interno.'), findsOneWidget);

    backend.handler = fallback;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Octubre de 2026'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('abrir un día y volver al mismo mes', (tester) async {
    serveMonths(
      days: [
        {'date': '2026-09-20', 'audio_count': 3, 'has_summary': true},
      ],
    );
    await openHistory(tester);
    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();

    await tester.tap(day(9, 20));
    await tester.pumpAndSettle();

    expect(historyCalls().last, endsWith('/api/v1/historial/2026-09-20'));
    expect(find.text('Domingo, 20 de septiembre de 2026'), findsOneWidget);
    expect(find.text('3 audios'), findsOneWidget);
    expect(find.textContaining('Día de trabajo en el proyecto'), findsOne);
    expect(find.textContaining('he ido al dentista'), findsOneWidget);
    expect(find.text('Tiempo de transcripción agotado.'), findsOneWidget);
    expect(find.text('Historial'), findsWidgets);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Septiembre de 2026'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('saltar al día con notas anterior', (tester) async {
    await openHistory(tester);
    await tester.tap(day(10, 14));
    await tester.pumpAndSettle();
    IconButton jump(String tooltip) => tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(tooltip),
        matching: find.byType(IconButton),
      ),
    );
    expect(jump('Día siguiente con notas').onPressed, isNull);

    await tester.tap(find.byTooltip('Día anterior con notas'));
    await tester.pumpAndSettle();

    expect(historyCalls().last, endsWith('/api/v1/historial/2026-10-13'));
    expect(find.text('Martes, 13 de octubre de 2026'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Octubre de 2026'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('los días sin notas no se abren', (tester) async {
    await openHistory(tester);

    await tester.tap(day(10, 5));
    await tester.pumpAndSettle();

    expect(historyCalls(), hasLength(1));
    expect(find.text('Octubre de 2026'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('día sin resumen y filtro por estado', (tester) async {
    final fallback = backend.handler;
    backend.handler = (options) =>
        options.uri.path.startsWith('/api/v1/historial/')
        ? jsonResponse(200, {
            'date': '2026-10-13',
            'entries': <Object?>[],
            'summary': null,
          })
        : fallback(options);
    await openHistory(tester);
    await tester.tap(day(10, 13));
    await tester.pumpAndSettle();

    expect(find.text('Sin resumen de este día.'), findsOneWidget);
    expect(find.text('Sin audios este día.'), findsOneWidget);

    await tester.tap(find.text('Error'));
    await tester.pumpAndSettle();

    expect(
      historyCalls().last,
      endsWith('/api/v1/historial/2026-10-13?status=ERROR'),
    );
    expect(find.text('Ningún audio con este estado.'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('escuchar una nota del día', (tester) async {
    await openHistory(tester);
    await tester.tap(day(10, 14));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey(42)),
        matching: find.byTooltip('Escuchar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(backend.calls, contains('GET /api/v1/audios/42/fichero'));
    expect(player.calls, ['load', 'speed 1.0', 'play']);

    await closeApp(tester);
  });

  testWidgets('el error al escuchar sale una sola vez', (tester) async {
    final fallback = backend.handler;
    backend.handler = (options) => options.uri.path.endsWith('/fichero')
        ? apiError(404, 'not_found', 'El audio no existe.')
        : fallback(options);
    await openHistory(tester);
    await tester.tap(day(10, 14));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey(44)),
        matching: find.byTooltip('Escuchar'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('El audio no existe.'), findsOneWidget);
    await tester.pumpAndSettle();

    await closeApp(tester);
  });

  test('fecha de la ruta del día', () {
    expect(parseDayParam('2026-10-14'), DateTime(2026, 10, 14));
    expect(parseDayParam('2026-02-30'), isNull);
    expect(parseDayParam('2026-1-05'), isNull);
    expect(parseDayParam('hoy'), isNull);
  });
}

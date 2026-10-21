import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary/app.dart';

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

  /// Arranca la app y abre Buscar.
  Future<void> openSearch(WidgetTester tester) async {
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
    await tester.tap(find.text('Buscar').last);
    await tester.pumpAndSettle();
  }

  /// Desmonta la app para que no quede vivo el sondeo del Diario.
  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  }

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  List<String> searchRequests() => [
    for (final request in backend.requests)
      if (request.uri.path == '/api/v1/busqueda')
        request.uri.queryParameters['q']!,
  ];

  testWidgets('busca al enviar, con los recordatorios primero', (tester) async {
    await openSearch(tester);
    expect(find.textContaining('Escribe lo que buscas'), findsOneWidget);

    await search(tester, '   ');
    expect(searchRequests(), isEmpty);

    await tester.enterText(find.byType(TextField), ' dentista ');
    await tester.pump();
    expect(searchRequests(), isEmpty);

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(searchRequests(), ['dentista']);
    expect(find.text('Dentista'), findsOneWidget);
    expect(find.text('Mar 20 oct 2026 · 10:30'), findsOneWidget);
    expect(find.textContaining('Hoy he ido al dentista'), findsOneWidget);
    expect(find.textContaining('Jue 8 oct 2026 · '), findsOneWidget);
    expect(find.text('Lun 5 oct 2026 · Resumen del día'), findsOneWidget);

    final reminders = tester.getTopLeft(find.text('Recordatorios')).dy;
    final note = tester.getTopLeft(find.textContaining('Jue 8 oct')).dy;
    final summary = tester.getTopLeft(find.textContaining('Lun 5 oct')).dy;
    expect(reminders < note && note < summary, isTrue);

    await closeApp(tester);
  });

  testWidgets('el resumen se despliega y «Ver día» abre el Historial', (
    tester,
  ) async {
    await openSearch(tester);
    await search(tester, 'dentista');
    expect(find.text('💼 Trabajo'), findsNothing);

    await tester.tap(find.text('Ver más'));
    await tester.pumpAndSettle();
    expect(find.text('💼 Trabajo'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'salud'), findsOneWidget);

    await tester.tap(find.text('Ver día').last);
    await tester.pumpAndSettle();

    expect(backend.calls, contains('GET /api/v1/historial/2026-10-05'));
    expect(find.text('Lunes, 5 de octubre de 2026'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('escuchar una nota encontrada', (tester) async {
    await openSearch(tester);
    await search(tester, 'dentista');

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('nota 42')),
        matching: find.byTooltip('Escuchar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(backend.calls, contains('GET /api/v1/audios/42/fichero'));
    expect(player.calls, ['load', 'speed 1.0', 'play']);

    await closeApp(tester);
  });

  testWidgets('sin resultados', (tester) async {
    final fallback = backend.handler;
    backend.handler = (options) => options.uri.path == '/api/v1/busqueda'
        ? jsonResponse(200, {
            'query': 'nada',
            'results': <Object?>[],
            'reminders': <Object?>[],
          })
        : fallback(options);
    await openSearch(tester);

    await search(tester, 'nada');

    expect(find.text('Sin resultados para «nada».'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('error y reintentar', (tester) async {
    final fallback = backend.handler;
    backend.handler = (options) => options.uri.path == '/api/v1/busqueda'
        ? apiError(500, 'internal_error', 'Error interno.')
        : fallback(options);
    await openSearch(tester);

    await search(tester, 'dentista');
    expect(find.text('Error interno.'), findsOneWidget);

    backend.handler = fallback;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(searchRequests(), ['dentista', 'dentista']);
    expect(find.text('Dentista'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('repetir la búsqueda la vuelve a pedir y borrar la quita', (
    tester,
  ) async {
    await openSearch(tester);
    await search(tester, 'dentista');
    // Al buscar se cierra el teclado: hay que volver al campo.
    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(searchRequests(), ['dentista', 'dentista']);

    await tester.tap(find.byTooltip('Borrar'));
    await tester.pumpAndSettle();

    expect(find.text('Dentista'), findsNothing);
    expect(find.textContaining('Escribe lo que buscas'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('la búsqueda se conserva al cambiar de sección', (tester) async {
    await openSearch(tester);
    await search(tester, 'dentista');

    await tester.tap(find.text('Diario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar').last);
    await tester.pumpAndSettle();

    expect(find.text('Dentista'), findsOneWidget);
    expect(searchRequests(), ['dentista']);

    await closeApp(tester);
  });
}

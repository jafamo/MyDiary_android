import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary/app.dart';
import 'package:mydiary/playback/note_player.dart';

import '../support/app_harness.dart';
import '../support/fake_http.dart';
import '../support/fake_player.dart';
import '../support/fake_recorder.dart';

void main() {
  late FakeAdapter backend;
  late FakePlayer player;
  late FakeRecorder recorder;
  late Directory directory;
  late ProviderContainer container;

  setUp(() {
    backend = fakeBackend();
    player = FakePlayer();
    recorder = FakeRecorder();
    directory = Directory.systemTemp.createTempSync('mydiary-test-');
    addTearDown(() => directory.deleteSync(recursive: true));
  });

  Future<void> startApp(WidgetTester tester) async {
    // Pantalla alta: las tres entradas del Diario a la vista.
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    container = createTestContainer(
      backend: backend,
      storage: MemoryTokenStorage(storedSession),
      recorder: recorder,
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
  }

  /// Desmonta la app para que no queden vivos el sondeo del Diario ni la grabación.
  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  }

  Finder inEntry(int id, Finder finder) =>
      find.descendant(of: find.byKey(ValueKey(id)), matching: finder);

  Future<void> tapInEntry(WidgetTester tester, int id, String tooltip) async {
    await tester.tap(inEntry(id, find.byTooltip(tooltip)));
    await tester.pumpAndSettle();
  }

  List<String> files() =>
      directory.listSync().map((e) => e.uri.pathSegments.last).toList();

  testWidgets('escuchar descarga el audio y lo reproduce', (tester) async {
    await startApp(tester);

    await tapInEntry(tester, 42, 'Escuchar');

    expect(backend.calls, contains('GET /api/v1/audios/42/fichero'));
    expect(files(), ['escucha-42.m4a']);
    expect(player.path, endsWith('/escucha-42.m4a'));
    expect(player.title, startsWith('Nota del 14/10 '));
    expect(player.calls, ['load', 'speed 1.0', 'play']);
    expect(inEntry(42, find.byTooltip('Pausa')), findsOneWidget);
    expect(inEntry(42, find.text('0:00 / 0:14')), findsOneWidget);
    expect(inEntry(43, find.byType(Slider)), findsNothing);

    await closeApp(tester);
  });

  testWidgets('pausar y continuar', (tester) async {
    await startApp(tester);
    await tapInEntry(tester, 42, 'Escuchar');

    await tapInEntry(tester, 42, 'Pausa');
    expect(player.calls.last, 'pause');
    expect(inEntry(42, find.byTooltip('Continuar')), findsOneWidget);

    await tapInEntry(tester, 42, 'Continuar');
    expect(player.calls.last, 'play');
    expect(inEntry(42, find.byTooltip('Pausa')), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('posición, salto y velocidad', (tester) async {
    await startApp(tester);
    await tapInEntry(tester, 42, 'Escuchar');

    player.emitPosition(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('0:05 / 0:14'), findsOneWidget);

    await tester.tap(find.byType(Slider));
    await tester.pumpAndSettle();
    expect(player.calls.last, startsWith('seek 0:00:07'));

    await tester.tap(find.text('1×'));
    await tester.pumpAndSettle();
    expect(find.text('1,5×'), findsOneWidget);
    expect(player.calls.last, 'speed 1.5');
    await tester.tap(find.text('1,5×'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2×'));
    await tester.pumpAndSettle();
    expect(find.text('1×'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('escuchar otra nota para la anterior y borra su fichero', (
    tester,
  ) async {
    await startApp(tester);
    await tapInEntry(tester, 42, 'Escuchar');

    await tapInEntry(tester, 43, 'Escuchar');

    expect(files(), ['escucha-43.m4a']);
    expect(player.calls, [
      'load',
      'speed 1.0',
      'play',
      'stop',
      'load',
      'speed 1.0',
      'play',
    ]);
    expect(inEntry(42, find.byTooltip('Escuchar')), findsOneWidget);
    expect(inEntry(43, find.byTooltip('Pausa')), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('al acabar el audio se borra el fichero', (tester) async {
    await startApp(tester);
    await tapInEntry(tester, 42, 'Escuchar');

    player.complete();
    await tester.pumpAndSettle();

    expect(files(), isEmpty);
    expect(player.calls.last, 'stop');
    expect(find.byTooltip('Escuchar'), findsNWidgets(3));
    expect(find.byType(Slider), findsNothing);

    await closeApp(tester);
  });

  testWidgets('parar desde la notificación', (tester) async {
    await startApp(tester);
    await tapInEntry(tester, 42, 'Escuchar');

    player.stopFromNotification();
    await tester.pumpAndSettle();

    expect(files(), isEmpty);
    expect(find.byTooltip('Escuchar'), findsNWidgets(3));

    await closeApp(tester);
  });

  testWidgets('el audio ya no existe', (tester) async {
    final respond = backend.handler;
    backend.handler = (options) => options.uri.path.endsWith('/fichero')
        ? apiError(404, 'not_found', 'El audio no existe.')
        : respond(options);
    await startApp(tester);

    await tapInEntry(tester, 42, 'Escuchar');

    expect(find.text('El audio no existe.'), findsOneWidget);
    expect(player.calls, isEmpty);
    expect(files(), isEmpty);
    expect(find.byTooltip('Escuchar'), findsNWidgets(3));

    await closeApp(tester);
  });

  testWidgets('cancelar la descarga', (tester) async {
    final download = Completer<ResponseBody>();
    final respond = backend.handler;
    backend.handler = (options) => options.uri.path.endsWith('/fichero')
        ? download.future
        : respond(options);
    await startApp(tester);

    await tester.tap(inEntry(42, find.byTooltip('Escuchar')));
    await tester.pump();
    expect(inEntry(42, find.byType(CircularProgressIndicator)), findsOneWidget);

    await tester.tap(inEntry(42, find.byTooltip('Cancelar')));
    download.complete(ResponseBody.fromBytes([0, 1], 200));
    await tester.pumpAndSettle();

    expect(player.calls, isEmpty);
    expect(files(), isEmpty);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byTooltip('Escuchar'), findsNWidgets(3));

    await closeApp(tester);
  });

  testWidgets('borra los ficheros de escucha de otra sesión', (tester) async {
    File('${directory.path}/escucha-1.ogg').writeAsBytesSync([1]);
    File('${directory.path}/otro.txt').writeAsBytesSync([1]);
    await startApp(tester);

    await tapInEntry(tester, 42, 'Escuchar');

    expect(files()..sort(), ['escucha-42.m4a', 'otro.txt']);

    await closeApp(tester);
  });

  testWidgets('grabar pausa la nota que suena', (tester) async {
    await startApp(tester);
    await tapInEntry(tester, 42, 'Escuchar');

    await tester.tap(find.byTooltip('Grabar nota'));
    await tester.pumpAndSettle();

    expect(player.calls.last, 'pause');
    expect(recorder.calls, ['start']);

    await closeApp(tester);
  });

  test('etiqueta de la velocidad', () {
    expect(speedLabel(1), '1×');
    expect(speedLabel(1.5), '1,5×');
    expect(speedLabel(2), '2×');
  });
}

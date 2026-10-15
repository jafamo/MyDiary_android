import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary/models/audio_upload.dart';
import 'package:mydiary/app.dart';
import 'package:mydiary/recording/recording_controller.dart';
import 'package:mydiary/recording/recording_sheet.dart';

import '../fixtures.dart';
import '../support/app_harness.dart';
import '../support/fake_http.dart';
import '../support/fake_recorder.dart';

void main() {
  late FakeAdapter backend;
  late FakeRecorder recorder;
  late Directory directory;
  late ProviderContainer container;

  setUp(() {
    backend = fakeBackend();
    // Diario sin nada pendiente: sin sondeo mientras pasa el tiempo de la grabación.
    final respond = backend.handler;
    backend.handler = (options) => options.uri.path == '/api/v1/diario'
        ? jsonResponse(200, {...fixture('diary'), 'entries': <Object?>[]})
        : respond(options);
    recorder = FakeRecorder();
    directory = Directory.systemTemp.createTempSync('mydiary-test-');
    addTearDown(() => directory.deleteSync(recursive: true));
  });

  Future<void> startApp(WidgetTester tester) async {
    container = createTestContainer(
      backend: backend,
      storage: MemoryTokenStorage(storedSession),
      recorder: recorder,
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

  /// Desmonta la app y libera los providers, para que el temporizador de una grabación
  /// en curso no quede vivo cuando el test comprueba que no hay timers.
  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  }

  Future<void> startRecording(WidgetTester tester) async {
    await startApp(tester);
    await tester.tap(find.byTooltip('Grabar nota'));
    await tester.pumpAndSettle();
  }

  /// Botón con [label], también los de icono (`FilledButton.icon` es una subclase privada).
  Finder buttonFinder(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );

  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.tap(buttonFinder(label));
    await tester.pumpAndSettle();
  }

  ButtonStyleButton button(WidgetTester tester, String label) =>
      tester.widget<ButtonStyleButton>(buttonFinder(label));

  List<File> notes() => directory.listSync().whereType<File>().toList();

  testWidgets('grabar y enviar una nota nueva', (tester) async {
    await startRecording(tester);

    expect(find.text('Grabando'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(recorder.calls, ['start']);
    expect(notes(), hasLength(1));

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('00:03'), findsOneWidget);

    await tapButton(tester, 'Enviar');

    expect(backend.calls, contains('POST /api/v1/audios'));
    expect(find.text('Nota enviada. Se está transcribiendo.'), findsOneWidget);
    expect(find.text('Grabando'), findsNothing);
    expect(notes(), isEmpty);
    expect(backend.calls.where((c) => c == 'GET /api/v1/diario'), hasLength(2));

    await closeApp(tester);
  });

  testWidgets('Enviar desactivado por debajo de 1 s', (tester) async {
    await startRecording(tester);

    expect(button(tester, 'Enviar').onPressed, isNull);

    await tester.pump(RecordingController.minDuration);
    expect(button(tester, 'Enviar').onPressed, isNotNull);

    await closeApp(tester);
  });

  testWidgets('pausar y continuar', (tester) async {
    await startRecording(tester);
    await tester.pump(const Duration(seconds: 2));

    await tapButton(tester, 'Pausa');
    expect(find.text('En pausa'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('00:02'), findsOneWidget);

    await tapButton(tester, 'Continuar');
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Grabando'), findsOneWidget);
    expect(find.text('00:03'), findsOneWidget);
    expect(recorder.calls, ['start', 'pause', 'resume']);

    await closeApp(tester);
  });

  testWidgets('nivel de entrada', (tester) async {
    await startRecording(tester);

    recorder.emitLevel(-30);
    await tester.pump();

    expect(container.read(recordingControllerProvider).levels, [0.5]);

    await closeApp(tester);
  });

  testWidgets('nota repetida', (tester) async {
    final respond = backend.handler;
    backend.handler = (options) => options.uri.path == '/api/v1/audios'
        ? jsonResponse(200, {...fixture('audio_upload'), 'result': 'duplicate'})
        : respond(options);
    await startRecording(tester);
    await tester.pump(const Duration(seconds: 2));

    await tapButton(tester, 'Enviar');

    expect(find.text('Esta nota ya estaba subida.'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('sin permiso no graba', (tester) async {
    recorder.permission = false;
    await startRecording(tester);

    expect(find.textContaining('Actívalo en los ajustes'), findsOneWidget);
    expect(recorder.calls, isEmpty);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Actívalo en los ajustes'), findsNothing);

    await closeApp(tester);
  });

  testWidgets('sin red al enviar conserva la nota y se puede reintentar', (
    tester,
  ) async {
    final respond = backend.handler;
    backend.handler = (options) => options.uri.path == '/api/v1/audios'
        ? networkDown(options)
        : respond(options);
    await startRecording(tester);
    await tester.pump(const Duration(seconds: 2));

    await tapButton(tester, 'Enviar');

    expect(find.text('No se pudo conectar con el servidor.'), findsOneWidget);
    expect(notes(), hasLength(1));

    backend.handler = respond;
    await tapButton(tester, 'Reintentar');

    expect(find.text('Nota enviada. Se está transcribiendo.'), findsOneWidget);
    expect(notes(), isEmpty);

    await closeApp(tester);
  });

  testWidgets('descartar pide confirmación y borra la nota', (tester) async {
    await startRecording(tester);
    await tester.pump(const Duration(seconds: 2));

    await tapButton(tester, 'Descartar');
    expect(find.text('¿Descartar la nota?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Descartar'));
    await tester.pumpAndSettle();

    expect(find.text('Grabando'), findsNothing);
    expect(recorder.calls, contains('cancel'));
    expect(backend.calls, isNot(contains('POST /api/v1/audios')));
    expect(notes(), isEmpty);

    await closeApp(tester);
  });

  testWidgets('atrás grabando pregunta antes de descartar', (tester) async {
    await startRecording(tester);
    await tester.pump(const Duration(seconds: 2));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar la nota?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Grabando'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('a los 45 min se pausa y no deja continuar', (tester) async {
    await startRecording(tester);

    await tester.pump(RecordingController.maxDuration);
    await tester.pump();

    expect(find.text('En pausa'), findsOneWidget);
    expect(find.text('45:00'), findsOneWidget);
    expect(find.text('Has llegado al máximo de 45 min.'), findsOneWidget);
    expect(button(tester, 'Continuar').onPressed, isNull);
    expect(button(tester, 'Enviar').onPressed, isNotNull);

    await closeApp(tester);
  });

  testWidgets('salir de la app pausa la grabación', (tester) async {
    await startRecording(tester);
    await tester.pump(const Duration(seconds: 2));

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();

    expect(find.text('En pausa'), findsOneWidget);
    expect(find.text('00:02'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('una pausa del sistema se refleja en la hoja', (tester) async {
    await startRecording(tester);

    recorder.systemPause();
    await tester.pumpAndSettle();

    expect(find.text('En pausa'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('borra las notas que quedaron de otra sesión', (tester) async {
    File('${directory.path}/nota-1.m4a').writeAsBytesSync([1]);
    File('${directory.path}/otro.txt').writeAsBytesSync([1]);

    await startRecording(tester);

    final names = directory
        .listSync()
        .map((e) => e.uri.pathSegments.last)
        .toList();
    expect(names, isNot(contains('nota-1.m4a')));
    expect(names, contains('otro.txt'));

    await closeApp(tester);
  });

  test('mensaje según el resultado', () {
    expect(
      uploadMessage(UploadResult.created),
      'Nota enviada. Se está transcribiendo.',
    );
    expect(
      uploadMessage(UploadResult.duplicate),
      'Esta nota ya estaba subida.',
    );
    expect(
      uploadMessage(UploadResult.retrying),
      'Esta nota ya estaba subida. Se vuelve a transcribir.',
    );
  });
}

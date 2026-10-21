import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary/auth/device_name.dart';
import 'package:mydiary/auth/session.dart';
import 'package:mydiary/auth/token_storage.dart';
import 'package:mydiary/config/app_config.dart';
import 'package:mydiary/providers.dart';
import 'package:mydiary/playback/player.dart';
import 'package:mydiary/recording/recorder.dart';

import '../fixtures.dart';
import 'fake_http.dart';
import 'fake_player.dart';
import 'fake_recorder.dart';

const testDeviceName = 'Test Phone (Android 16)';

const storedSession = Session(
  token: 'guardado',
  username: 'jfarinos',
  deviceName: 'Nombre antiguo',
);

/// Almacenamiento seguro en memoria.
class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage([this.session]);

  Session? session;

  @override
  Future<Session?> read() async => session;

  @override
  Future<void> write(Session session) async => this.session = session;

  @override
  Future<void> clear() async => session = null;
}

/// Backend falso con las respuestas felices de login, me, logout, diario, subida, descarga e
/// historial, resúmenes y búsqueda. Cada test cambia [FakeAdapter.handler] para los casos de error.
FakeAdapter fakeBackend() => FakeAdapter((options) {
  return switch ('${options.method} ${options.uri.path}') {
    'POST /api/v1/login' => jsonResponse(200, fixture('login')),
    'GET /api/v1/me' => jsonResponse(200, fixture('me')),
    'POST /api/v1/logout' => emptyResponse(204),
    'GET /api/v1/diario' => jsonResponse(200, fixture('diary')),
    'POST /api/v1/audios' => jsonResponse(201, fixture('audio_upload')),
    'GET /api/v1/historial' => jsonResponse(200, fixture('history_month')),
    final call when call.startsWith('GET /api/v1/historial/') => jsonResponse(
      200,
      {...fixture('history_day'), 'date': call.split('/').last},
    ),
    'GET /api/v1/resumenes' => jsonResponse(200, fixture('summaries_page')),
    'GET /api/v1/busqueda' => jsonResponse(200, fixture('search')),
    final call
        when call.startsWith('GET /api/v1/audios/') &&
            call.endsWith('/fichero') =>
      ResponseBody.fromBytes(
        [0, 1, 2, 3],
        200,
        headers: {
          Headers.contentTypeHeader: ['audio/mp4'],
        },
      ),
    final call => throw StateError('Petición inesperada: $call'),
  };
});

/// [recorder], [player] y [temporaryDirectory] sustituyen al micrófono, al reproductor y a la
/// carpeta temporal.
ProviderContainer createTestContainer({
  required FakeAdapter backend,
  required MemoryTokenStorage storage,
  FakeRecorder? recorder,
  FakePlayer? player,
  Directory? temporaryDirectory,
}) {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(
        AppConfig.parse('http://backend.test:9008'),
      ),
      dioProvider.overrideWithValue(Dio()..httpClientAdapter = backend),
      tokenStorageProvider.overrideWithValue(storage),
      deviceNameProvider.overrideWith((ref) async => testDeviceName),
      if (recorder != null) recorderProvider.overrideWith((ref) => recorder),
      playerProvider.overrideWithValue(player ?? FakePlayer()),
      if (temporaryDirectory != null)
        temporaryDirectoryProvider.overrideWith(
          (ref) async => temporaryDirectory,
        ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Sin conexión con el servidor.
Never networkDown(Object? _) => throw const SocketException('Sin red');

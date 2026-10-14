import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary/auth/device_name.dart';
import 'package:mydiary/auth/session.dart';
import 'package:mydiary/auth/token_storage.dart';
import 'package:mydiary/config/app_config.dart';
import 'package:mydiary/providers.dart';

import '../fixtures.dart';
import 'fake_http.dart';

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

/// Backend falso con las respuestas felices de login, me y logout. Cada test cambia
/// [FakeAdapter.handler] para los casos de error.
FakeAdapter fakeBackend() => FakeAdapter((options) {
  return switch ('${options.method} ${options.uri.path}') {
    'POST /api/v1/login' => jsonResponse(200, fixture('login')),
    'GET /api/v1/me' => jsonResponse(200, fixture('me')),
    'POST /api/v1/logout' => emptyResponse(204),
    final call => throw StateError('Petición inesperada: $call'),
  };
});

ProviderContainer createTestContainer({
  required FakeAdapter backend,
  required MemoryTokenStorage storage,
}) {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(
        AppConfig.parse('http://backend.test:9008'),
      ),
      dioProvider.overrideWithValue(Dio()..httpClientAdapter = backend),
      tokenStorageProvider.overrideWithValue(storage),
      deviceNameProvider.overrideWith((ref) async => testDeviceName),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Sin conexión con el servidor.
Never networkDown(Object? _) => throw const SocketException('Sin red');

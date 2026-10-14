import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary/api/api_exception.dart';
import 'package:mydiary/auth/auth_token.dart';
import 'package:mydiary/auth/session.dart';
import 'package:mydiary/auth/session_notifier.dart';
import 'package:mydiary/providers.dart';

import '../fixtures.dart';
import '../support/app_harness.dart';
import '../support/fake_http.dart';

void main() {
  late FakeAdapter backend;
  late MemoryTokenStorage storage;

  setUp(() {
    backend = fakeBackend();
    storage = MemoryTokenStorage();
  });

  group('arranque', () {
    test('sin sesión guardada no llama al backend', () async {
      final container = createTestContainer(backend: backend, storage: storage);

      expect(await container.read(sessionProvider.future), isNull);
      expect(backend.calls, isEmpty);
    });

    test('sesión válida: /me actualiza usuario y dispositivo', () async {
      storage.session = storedSession;
      final container = createTestContainer(backend: backend, storage: storage);

      final session = await container.read(sessionProvider.future);

      expect(backend.calls, ['GET /api/v1/me']);
      expect(
        backend.requests.single.headers['Authorization'],
        'Bearer guardado',
      );
      expect(session!.deviceName, testDeviceName);
      expect(storage.session!.deviceName, testDeviceName);
      expect(container.read(authTokenProvider), 'guardado');
    });

    test('token revocado: borra la sesión guardada', () async {
      storage.session = storedSession;
      backend.handler = (_) =>
          apiError(401, 'unauthorized', 'Token ausente, inválido o caducado.');
      final container = createTestContainer(backend: backend, storage: storage);

      expect(await container.read(sessionProvider.future), isNull);
      expect(storage.session, isNull);
      expect(container.read(authTokenProvider), isNull);
    });

    test('sin red: entra con la sesión guardada', () async {
      storage.session = storedSession;
      backend.handler = networkDown;
      final container = createTestContainer(backend: backend, storage: storage);

      final session = await container.read(sessionProvider.future);

      expect(session!.token, 'guardado');
      expect(storage.session, isNotNull);
    });
  });

  group('login', () {
    test('correcto: guarda la sesión y el token', () async {
      final container = createTestContainer(backend: backend, storage: storage);
      await container.read(sessionProvider.future);

      await container
          .read(sessionProvider.notifier)
          .login('jfarinos', 'secreto');

      final body = backend.requests.single.data as Map<String, Object?>;
      expect(body, {
        'username': 'jfarinos',
        'password': 'secreto',
        'device_name': testDeviceName,
      });
      final token = fixture('login')['token'];
      expect(container.read(sessionProvider).value!.token, token);
      expect(storage.session!.token, token);
      expect(container.read(authTokenProvider), token);
    });

    test('incorrecto: propaga el error y no guarda nada', () async {
      backend.handler = (_) =>
          apiError(401, 'unauthorized', 'Usuario o contraseña incorrectos.');
      final container = createTestContainer(backend: backend, storage: storage);
      await container.read(sessionProvider.future);

      await expectLater(
        container.read(sessionProvider.notifier).login('jfarinos', 'mal'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Usuario o contraseña incorrectos.',
          ),
        ),
      );
      expect(storage.session, isNull);
      expect(container.read(sessionProvider).value, isNull);
    });
  });

  group('logout', () {
    test('revoca el token y borra la sesión', () async {
      storage.session = storedSession;
      final container = createTestContainer(backend: backend, storage: storage);
      await container.read(sessionProvider.future);

      await container.read(sessionProvider.notifier).logout();

      expect(backend.calls.last, 'POST /api/v1/logout');
      expect(storage.session, isNull);
      expect(container.read(sessionProvider).value, isNull);
      expect(container.read(authTokenProvider), isNull);
    });

    test('sin red: borra la sesión igualmente', () async {
      storage.session = storedSession;
      final container = createTestContainer(backend: backend, storage: storage);
      await container.read(sessionProvider.future);
      backend.handler = networkDown;

      await container.read(sessionProvider.notifier).logout();

      expect(storage.session, isNull);
      expect(container.read(sessionProvider).value, isNull);
    });
  });

  test('un 401 en otra petición borra la sesión guardada', () async {
    storage.session = storedSession;
    final container = createTestContainer(backend: backend, storage: storage);
    await container.read(sessionProvider.future);
    backend.handler = (_) =>
        apiError(401, 'unauthorized', 'Token ausente, inválido o caducado.');

    await expectLater(
      container.read(apiClientProvider).get('/diario', parse: (_) => null),
      throwsA(isA<ApiException>()),
    );

    expect(container.read(sessionProvider).value, isNull);
    expect(storage.session, isNull);
  });

  test('modelos de login y me', () {
    final login = LoginResult.fromJson(fixture('login'));
    final me = Me.fromJson(fixture('me'));

    expect(login.tokenId, 7);
    expect(login.expiresAt, DateTime.utc(2027, 1, 12, 10));
    expect(me.username, 'jfarinos');
    expect(me.lastUsedAt, isNull);
  });
}

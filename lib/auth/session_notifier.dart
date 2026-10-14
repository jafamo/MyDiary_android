import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/json.dart';
import '../providers.dart';
import 'auth_token.dart';
import 'device_name.dart';
import 'session.dart';
import 'token_storage.dart';

/// Sesión de la app. Mientras carga, se está comprobando la sesión guardada.
final sessionProvider = AsyncNotifierProvider<SessionNotifier, Session?>(
  SessionNotifier.new,
);

class SessionNotifier extends AsyncNotifier<Session?> {
  ApiClient get _api => ref.read(apiClientProvider);
  TokenStorage get _storage => ref.read(tokenStorageProvider);

  @override
  Future<Session?> build() async {
    // Un 401 en cualquier petición borra el token (ApiClient); aquí se borra además
    // la sesión guardada y se vuelve al login.
    ref.listen(authTokenProvider, (_, token) {
      if (token == null && state.value != null) {
        _storage.clear();
        state = const AsyncData(null);
      }
    });

    Session? stored;
    try {
      stored = await _storage.read();
    } on Exception {
      // Almacenamiento ilegible (p. ej. clave del Keystore perdida): se empieza de cero.
      await _storage.clear();
    }
    if (stored == null) {
      return null;
    }

    ref.read(authTokenProvider.notifier).set(stored.token);
    try {
      final me = await _api.get(
        '/me',
        parse: (json) => Me.fromJson(asJson(json)),
      );
      final session = stored.copyWith(
        username: me.username,
        deviceName: me.deviceName,
      );
      await _storage.write(session);
      return session;
    } on ApiException catch (e) {
      if (e.code == ApiException.unauthorized) {
        await _storage.clear();
        return null;
      }
      // Sin red u otro fallo: no se sabe si el token vale, se entra con la sesión guardada.
      return stored;
    }
  }

  /// Lanza [ApiException] si el login falla; en ese caso no cambia nada.
  Future<void> login(String username, String password) async {
    final deviceName = await ref.read(deviceNameProvider.future);
    final result = await _api.post(
      ApiClient.loginPath,
      body: {
        'username': username,
        'password': password,
        'device_name': deviceName,
      },
      parse: (json) => LoginResult.fromJson(asJson(json)),
    );

    final session = Session(
      token: result.token,
      username: username,
      deviceName: result.deviceName,
    );
    await _storage.write(session);
    ref.read(authTokenProvider.notifier).set(session.token);
    state = AsyncData(session);
  }

  /// Revoca el token en el servidor si puede y olvida la sesión en cualquier caso.
  Future<void> logout() async {
    try {
      await _api.post('/logout', parse: (_) => null);
    } on ApiException {
      // Sin red o token ya inválido: el dispositivo olvida la sesión igualmente.
    }
    await _storage.clear();
    state = const AsyncData(null);
    ref.read(authTokenProvider.notifier).clear();
  }
}

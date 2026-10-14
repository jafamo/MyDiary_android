import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'session.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Sesión guardada en el almacenamiento seguro del sistema (Keystore en Android,
/// Keychain en iOS). Es el único sitio donde se guarda el token.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // Solo en este dispositivo (sin iCloud) y legible en segundo plano tras
            // el primer desbloqueo, para las subidas de audio (fase 3).
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const _token = 'token';
  static const _username = 'username';
  static const _deviceName = 'device_name';

  final FlutterSecureStorage _storage;

  /// `null` si no hay sesión guardada completa.
  Future<Session?> read() async {
    final token = await _storage.read(key: _token);
    final username = await _storage.read(key: _username);
    final deviceName = await _storage.read(key: _deviceName);
    if (token == null || username == null || deviceName == null) {
      return null;
    }

    return Session(token: token, username: username, deviceName: deviceName);
  }

  Future<void> write(Session session) async {
    await _storage.write(key: _token, value: session.token);
    await _storage.write(key: _username, value: session.username);
    await _storage.write(key: _deviceName, value: session.deviceName);
  }

  Future<void> clear() async {
    await _storage.delete(key: _token);
    await _storage.delete(key: _username);
    await _storage.delete(key: _deviceName);
  }
}

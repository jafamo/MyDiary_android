import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Token de la API en uso, o `null` sin sesión.
///
/// De momento solo en memoria; la fase 1 lo persiste en `flutter_secure_storage`
/// sin cambiar cómo se lee.
final authTokenProvider = NotifierProvider<AuthTokenNotifier, String?>(
  AuthTokenNotifier.new,
);

class AuthTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String token) => state = token;

  void clear() => state = null;
}

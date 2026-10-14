import '../api/json.dart';

/// Sesión iniciada en este dispositivo.
class Session {
  const Session({
    required this.token,
    required this.username,
    required this.deviceName,
  });

  final String token;
  final String username;

  /// Nombre con el que el token aparece en `app:user:token:list`.
  final String deviceName;

  Session copyWith({String? username, String? deviceName}) => Session(
    token: token,
    username: username ?? this.username,
    deviceName: deviceName ?? this.deviceName,
  );
}

/// Respuesta de `POST /api/v1/login`.
class LoginResult {
  const LoginResult({
    required this.token,
    required this.tokenId,
    required this.deviceName,
    required this.expiresAt,
  });

  factory LoginResult.fromJson(Json json) => LoginResult(
    token: json.string('token'),
    tokenId: json.integer('token_id'),
    deviceName: json.string('device_name'),
    expiresAt: json.instant('expires_at'),
  );

  final String token;
  final int tokenId;
  final String deviceName;
  final DateTime expiresAt;
}

/// Respuesta de `GET /api/v1/me`.
class Me {
  const Me({
    required this.username,
    required this.tokenId,
    required this.deviceName,
    required this.createdAt,
    required this.expiresAt,
    this.lastUsedAt,
  });

  factory Me.fromJson(Json json) => Me(
    username: json.string('username'),
    tokenId: json.integer('token_id'),
    deviceName: json.string('device_name'),
    createdAt: json.instant('created_at'),
    lastUsedAt: json.instantOrNull('last_used_at'),
    expiresAt: json.instant('expires_at'),
  );

  final String username;
  final int tokenId;
  final String deviceName;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final DateTime expiresAt;
}

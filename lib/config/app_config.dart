/// Configuración de compilación, pasada con `--dart-define-from-file=env/<entorno>.json`
/// (ver `env.example.json`).
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  static const apiBaseUrlKey = 'API_BASE_URL';

  /// URL del backend, sin `/api/v1` (p. ej. `http://10.0.2.2:9008`).
  final Uri apiBaseUrl;

  /// Lanza [ConfigException] si falta `API_BASE_URL` o no es una URL http(s).
  factory AppConfig.fromEnvironment() =>
      AppConfig.parse(const String.fromEnvironment(apiBaseUrlKey));

  factory AppConfig.parse(String apiBaseUrl) {
    final uri = Uri.tryParse(apiBaseUrl.trim());
    if (uri == null ||
        !(uri.isScheme('http') || uri.isScheme('https')) ||
        uri.host.isEmpty) {
      throw ConfigException(
        '$apiBaseUrlKey no está configurada o no es una URL http(s): "$apiBaseUrl".',
      );
    }

    return AppConfig(apiBaseUrl: uri);
  }
}

class ConfigException implements Exception {
  const ConfigException(this.message);

  final String message;

  @override
  String toString() => 'ConfigException: $message';
}

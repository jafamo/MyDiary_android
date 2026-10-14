/// Cualquier fallo de una petición a la API.
///
/// [code] es estable y es por lo que se ramifica; [message] es texto para mostrar.
/// Además de los códigos del backend (`conflict`, `validation_failed`...), el cliente
/// usa [networkError] e [invalidResponse].
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.retryAfter,
    this.cause,
  });

  /// Sin respuesta del servidor: sin red, DNS, timeout.
  static const networkError = 'network_error';

  /// Respuesta correcta que no se puede interpretar como el modelo esperado.
  static const invalidResponse = 'invalid_response';

  static const unauthorized = 'unauthorized';
  static const tooManyRequests = 'too_many_requests';

  /// `null` si no hubo respuesta.
  final int? statusCode;
  final String code;
  final String message;

  /// Solo en `429`: cuánto esperar antes de reintentar (cabecera `Retry-After`).
  final Duration? retryAfter;

  /// Error original en `invalid_response`, para depurar (no se muestra al usuario).
  final Object? cause;

  /// Código para una respuesta de error que no trae el formato `{code, message}` de la API
  /// (p. ej. el `413` en HTML de nginx). Misma tabla que el backend.
  static String codeForStatus(int statusCode) => switch (statusCode) {
    400 => 'bad_request',
    401 => unauthorized,
    403 => 'forbidden',
    404 => 'not_found',
    405 => 'method_not_allowed',
    409 => 'conflict',
    422 => 'validation_failed',
    429 => tooManyRequests,
    500 => 'internal_error',
    _ => 'http_$statusCode',
  };

  @override
  String toString() =>
      'ApiException($statusCode, $code): $message${cause == null ? '' : ' [$cause]'}';
}

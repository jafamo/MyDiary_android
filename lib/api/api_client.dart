import 'package:dio/dio.dart';

import 'api_exception.dart';

typedef JsonParser<T> = T Function(Object? json);

/// Único punto de acceso a `/api/v1`. Las pantallas y providers no usan `Dio` directamente.
///
/// Todo fallo sale como [ApiException]. Ante un `401` (salvo en el login, donde significa
/// credenciales incorrectas) avisa con [onUnauthorized] para que la app olvide el token.
class ApiClient {
  ApiClient({
    required Uri baseUrl,
    required this._token,
    required this._onUnauthorized,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl =
          '${baseUrl.toString().replaceFirst(RegExp(r'/+$'), '')}/api/v1'
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 30)
      ..responseType = ResponseType.json
      ..headers['Accept'] = 'application/json';
  }

  static const loginPath = '/login';

  final String? Function() _token;
  final void Function() _onUnauthorized;
  final Dio _dio;

  Future<T> get<T>(
    String path, {
    Map<String, Object?>? query,
    required JsonParser<T> parse,
  }) => _send('GET', path, query: query, parse: parse);

  /// [body] es un objeto JSON o un [FormData] (subida multipart). [onSendProgress]
  /// recibe los bytes enviados y el total.
  Future<T> post<T>(
    String path, {
    Object? body,
    required JsonParser<T> parse,
    ProgressCallback? onSendProgress,
  }) => _send(
    'POST',
    path,
    body: body,
    parse: parse,
    onSendProgress: onSendProgress,
  );

  Future<T> patch<T>(
    String path, {
    Object? body,
    required JsonParser<T> parse,
  }) => _send('PATCH', path, body: body, parse: parse);

  Future<void> delete(String path) => _send('DELETE', path, parse: (_) {});

  Future<T> _send<T>(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    required JsonParser<T> parse,
    ProgressCallback? onSendProgress,
  }) async {
    final token = _token();
    final Response<Object?> response;
    try {
      response = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: query,
        onSendProgress: onSendProgress,
        options: Options(
          method: method,
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      throw _toApiException(e, path);
    }

    try {
      return parse(response.data);
    } on FormatException catch (e) {
      throw _invalidResponse(response.statusCode, e);
    } on TypeError catch (e) {
      throw _invalidResponse(response.statusCode, e);
    }
  }

  ApiException _toApiException(DioException e, String path) {
    final response = e.response;
    if (response == null) {
      if (e.error is FormatException) {
        return _invalidResponse(null, e.error);
      }
      return const ApiException(
        statusCode: null,
        code: ApiException.networkError,
        message: 'No se pudo conectar con el servidor.',
      );
    }

    final status = response.statusCode ?? 0;
    var code = ApiException.codeForStatus(status);
    var message = 'El servidor respondió con un error ($status).';
    final data = response.data;
    if (data is Map && data['code'] is String && data['message'] is String) {
      code = data['code'] as String;
      message = data['message'] as String;
    }

    if (status == 401 && path != loginPath) {
      _onUnauthorized();
    }

    return ApiException(
      statusCode: status,
      code: code,
      message: message,
      retryAfter: status == 429 ? _retryAfter(response) : null,
    );
  }

  Duration? _retryAfter(Response<Object?> response) {
    final seconds = int.tryParse(response.headers.value('retry-after') ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }

  ApiException _invalidResponse(int? statusCode, Object? cause) => ApiException(
    statusCode: statusCode,
    code: ApiException.invalidResponse,
    message: 'Respuesta inesperada del servidor.',
    cause: cause,
  );
}

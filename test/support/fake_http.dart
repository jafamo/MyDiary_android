import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Adaptador HTTP falso: registra las peticiones y responde con [handler].
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  FutureOr<ResponseBody> Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  /// Rutas pedidas (`GET /api/v1/me`...), para comprobar qué se llamó.
  List<String> get calls =>
      requests.map((r) => '${r.method} ${r.uri.path}').toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(
  int status,
  Object? body, {
  Map<String, List<String>> headers = const {},
}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
    ...headers,
  },
);

ResponseBody emptyResponse(int status) => ResponseBody.fromString('', status);

ResponseBody apiError(int status, String code, String message) =>
    jsonResponse(status, {'code': code, 'message': message});

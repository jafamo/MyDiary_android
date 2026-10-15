import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary/api/api_client.dart';
import 'package:mydiary/api/api_exception.dart';
import 'package:mydiary/api/json.dart';
import 'package:mydiary/models/audio.dart';

import '../fixtures.dart';
import '../support/fake_http.dart';

void main() {
  late FakeAdapter adapter;
  late String? token;
  late int unauthorizedCalls;
  late ApiClient client;

  void respond(ResponseBody Function(RequestOptions options) handler) {
    adapter = FakeAdapter(handler);
    client = ApiClient(
      baseUrl: Uri.parse('http://backend.test:9008/'),
      token: () => token,
      onUnauthorized: () => unauthorizedCalls++,
      dio: Dio()..httpClientAdapter = adapter,
    );
  }

  Future<ApiException> failure(Future<Object?> request) async {
    try {
      await request;
    } on ApiException catch (e) {
      return e;
    }
    fail('Se esperaba ApiException');
  }

  setUp(() {
    token = null;
    unauthorizedCalls = 0;
  });

  test('envía el token como Bearer sobre /api/v1', () async {
    token = 'abc';
    respond((_) => jsonResponse(200, fixture('audio_transcribed')));

    final audio = await client.get(
      '/audios/42',
      parse: (json) => Audio.fromJson(asJson(json)),
    );

    final request = adapter.requests.single;
    expect(request.uri.toString(), 'http://backend.test:9008/api/v1/audios/42');
    expect(request.headers['Authorization'], 'Bearer abc');
    expect(request.headers['Accept'], 'application/json');
    expect(audio.id, 42);
  });

  test('sin token no envía Authorization', () async {
    respond((_) => jsonResponse(200, <String, Object?>{}));

    await client.post(
      ApiClient.loginPath,
      body: {'username': 'u'},
      parse: (_) => null,
    );

    expect(
      adapter.requests.single.headers.containsKey('Authorization'),
      isFalse,
    );
  });

  test('subida multipart con aviso de progreso', () async {
    token = 'abc';
    respond((_) => jsonResponse(201, <String, Object?>{}));
    void progress(int sent, int total) {}

    await client.post(
      '/audios',
      body: FormData.fromMap({
        'file': MultipartFile.fromBytes([1, 2, 3], filename: 'nota.m4a'),
      }),
      parse: (_) => null,
      onSendProgress: progress,
    );

    final request = adapter.requests.single;
    expect(request.data, isA<FormData>());
    expect((request.data as FormData).files.single.key, 'file');
    expect(request.onSendProgress, isNotNull);
  });

  test('pasa los parámetros de consulta', () async {
    token = 'abc';
    respond((_) => jsonResponse(200, <String, Object?>{}));

    await client.get('/diario', query: {'status': 'ERROR'}, parse: (_) => null);

    expect(adapter.requests.single.uri.queryParameters, {'status': 'ERROR'});
  });

  test('error de la API con code y message', () async {
    token = 'abc';
    respond(
      (_) => jsonResponse(409, {
        'code': 'conflict',
        'message': 'Solo se pueden editar audios transcritos.',
      }),
    );

    final e = await failure(
      client.patch(
        '/audios/1/transcripcion',
        body: {'content': 'x'},
        parse: (_) => null,
      ),
    );

    expect(e.statusCode, 409);
    expect(e.code, 'conflict');
    expect(e.message, 'Solo se pueden editar audios transcritos.');
    expect(unauthorizedCalls, 0);
  });

  test('error sin formato de la API (413 en HTML de nginx)', () async {
    token = 'abc';
    respond(
      (_) => ResponseBody.fromString(
        '<html>413 Request Entity Too Large</html>',
        413,
        headers: {
          Headers.contentTypeHeader: ['text/html'],
        },
      ),
    );

    final e = await failure(client.post('/audios', parse: (_) => null));

    expect(e.statusCode, 413);
    expect(e.code, 'http_413');
  });

  test('error conocido sin cuerpo toma el code de la tabla', () async {
    token = 'abc';
    respond((_) => ResponseBody.fromString('', 404));

    final e = await failure(client.delete('/recordatorios/9'));

    expect(e.code, 'not_found');
  });

  test('sin conexión es network_error', () async {
    respond((_) => throw const SocketException('Connection refused'));

    final e = await failure(client.get('/me', parse: (_) => null));

    expect(e.statusCode, isNull);
    expect(e.code, ApiException.networkError);
  });

  test('401 en una petición autenticada avisa de sesión caducada', () async {
    token = 'revocado';
    respond(
      (_) => jsonResponse(401, {
        'code': 'unauthorized',
        'message': 'Token no válido.',
      }),
    );

    final e = await failure(client.get('/me', parse: (_) => null));

    expect(e.code, ApiException.unauthorized);
    expect(unauthorizedCalls, 1);
  });

  test('401 en el login no es sesión caducada', () async {
    respond(
      (_) => jsonResponse(401, {
        'code': 'unauthorized',
        'message': 'Credenciales incorrectas.',
      }),
    );

    final e = await failure(
      client.post(ApiClient.loginPath, parse: (_) => null),
    );

    expect(e.code, ApiException.unauthorized);
    expect(unauthorizedCalls, 0);
  });

  test('429 incluye Retry-After', () async {
    respond(
      (_) => jsonResponse(
        429,
        {'code': 'too_many_requests', 'message': 'Demasiados intentos.'},
        headers: {
          'retry-after': ['840'],
        },
      ),
    );

    final e = await failure(
      client.post(ApiClient.loginPath, parse: (_) => null),
    );

    expect(e.code, ApiException.tooManyRequests);
    expect(e.retryAfter, const Duration(seconds: 840));
  });

  test(
    'respuesta 200 que no encaja con el modelo es invalid_response',
    () async {
      token = 'abc';
      respond(
        (_) => jsonResponse(200, fixture('audio_transcribed')..remove('id')),
      );

      final e = await failure(
        client.get('/audios/42', parse: (json) => Audio.fromJson(asJson(json))),
      );

      expect(e.statusCode, 200);
      expect(e.code, ApiException.invalidResponse);
      expect(e.cause, isA<FormatException>());
    },
  );

  test('204 sin cuerpo', () async {
    token = 'abc';
    respond((_) => ResponseBody.fromString('', 204));

    await client.delete('/recordatorios/9');

    expect(adapter.requests.single.method, 'DELETE');
  });
}

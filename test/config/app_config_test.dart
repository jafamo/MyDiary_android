import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary/app.dart';
import 'package:mydiary/config/app_config.dart';

void main() {
  test('URL válida', () {
    final config = AppConfig.parse('http://10.0.2.2:9008');

    expect(config.apiBaseUrl.host, '10.0.2.2');
    expect(config.apiBaseUrl.port, 9008);
  });

  for (final value in ['', 'localhost:9008', 'ftp://servidor', 'http://']) {
    test('valor no válido "$value" lanza ConfigException', () {
      expect(
        () => AppConfig.parse(value),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains(AppConfig.apiBaseUrlKey),
          ),
        ),
      );
    });
  }

  testWidgets('la pantalla de error nombra la clave que falta', (tester) async {
    String message;
    try {
      AppConfig.parse('');
      fail('Se esperaba ConfigException');
    } on ConfigException catch (e) {
      message = e.message;
    }

    await tester.pumpWidget(ConfigErrorApp(message: message));

    expect(find.text('Error de configuración'), findsOneWidget);
    expect(find.textContaining('API_BASE_URL'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary/app.dart';
import 'package:mydiary/providers.dart';
import 'package:mydiary/screens/home_screen.dart';
import 'package:mydiary/screens/login_screen.dart';
import 'package:mydiary/screens/splash_screen.dart';

import 'support/app_harness.dart';
import 'support/fake_http.dart';

/// Flujo de navegación y sesión de punta a punta, con el backend falso.
void main() {
  late FakeAdapter backend;
  late MemoryTokenStorage storage;
  late ProviderContainer container;

  setUp(() {
    backend = fakeBackend();
    storage = MemoryTokenStorage();
  });

  Future<void> startApp(WidgetTester tester) async {
    container = createTestContainer(backend: backend, storage: storage);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MyDiaryApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillLogin(WidgetTester tester, String user, String pass) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Usuario'), user);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      pass,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();
  }

  FilledButton enterButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Entrar'));

  testWidgets('pantalla de carga mientras se comprueba la sesión', (
    tester,
  ) async {
    storage.session = storedSession;
    final me = Completer<ResponseBody>();
    backend.handler = (_) => me.future;
    container = createTestContainer(backend: backend, storage: storage);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MyDiaryApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);

    me.complete(emptyResponse(204));
    await tester.pumpAndSettle();
  });

  testWidgets('sin sesión muestra el login', (tester) async {
    await startApp(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('con sesión válida muestra el inicio', (tester) async {
    storage.session = storedSession;
    await startApp(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('token revocado al arrancar lleva al login', (tester) async {
    storage.session = storedSession;
    backend.handler = (_) =>
        apiError(401, 'unauthorized', 'Token ausente, inválido o caducado.');
    await startApp(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(storage.session, isNull);
  });

  testWidgets('sin red al arrancar entra con la sesión guardada', (
    tester,
  ) async {
    storage.session = storedSession;
    backend.handler = networkDown;
    await startApp(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('login correcto lleva al inicio', (tester) async {
    await startApp(tester);

    await fillLogin(tester, 'jfarinos', 'secreto');

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(storage.session, isNotNull);
  });

  testWidgets('campos vacíos no envían nada', (tester) async {
    await startApp(tester);

    await fillLogin(tester, 'jfarinos', '');

    expect(find.text('Obligatorio'), findsOneWidget);
    expect(backend.calls, isEmpty);
  });

  testWidgets('credenciales incorrectas muestran el mensaje del backend', (
    tester,
  ) async {
    await startApp(tester);
    backend.handler = (_) =>
        apiError(401, 'unauthorized', 'Usuario o contraseña incorrectos.');

    await fillLogin(tester, 'jfarinos', 'mal');

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('⚠ Usuario o contraseña incorrectos.'), findsOneWidget);
    expect(storage.session, isNull);
  });

  testWidgets('sin red en el login avisa de la conexión', (tester) async {
    await startApp(tester);
    backend.handler = networkDown;

    await fillLogin(tester, 'jfarinos', 'secreto');

    expect(find.text('⚠ No se pudo conectar con el servidor.'), findsOneWidget);
  });

  testWidgets('429 bloquea el botón con cuenta atrás hasta Retry-After', (
    tester,
  ) async {
    await startApp(tester);
    backend.handler = (_) => jsonResponse(
      429,
      {
        'code': 'too_many_requests',
        'message': 'Demasiados intentos de login. Inténtalo más tarde.',
      },
      headers: {
        'retry-after': ['840'],
      },
    );

    await fillLogin(tester, 'jfarinos', 'mal');

    expect(
      find.text('⚠ Demasiados intentos. Prueba de nuevo en 14:00.'),
      findsOneWidget,
    );
    expect(enterButton(tester).onPressed, isNull);

    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('13:59'), findsOneWidget);

    await tester.pump(const Duration(seconds: 840));
    expect(enterButton(tester).onPressed, isNotNull);
    expect(find.textContaining('Demasiados intentos'), findsNothing);
  });

  group('cerrar sesión', () {
    Future<void> openLogout(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('jfarinos'), findsOneWidget);
      expect(find.text(testDeviceName), findsOneWidget);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
    }

    testWidgets('confirmando vuelve al login', (tester) async {
      storage.session = storedSession;
      await startApp(tester);

      await openLogout(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(backend.calls.last, 'POST /api/v1/logout');
      expect(storage.session, isNull);
    });

    testWidgets('cancelando sigue en el inicio', (tester) async {
      storage.session = storedSession;
      await startApp(tester);

      await openLogout(tester);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(backend.calls, isNot(contains('POST /api/v1/logout')));
    });
  });

  testWidgets('un 401 en otra petición lleva al login', (tester) async {
    storage.session = storedSession;
    await startApp(tester);
    backend.handler = (_) =>
        apiError(401, 'unauthorized', 'Token ausente, inválido o caducado.');

    // Sin await: en testWidgets el tiempo solo avanza con pump.
    container
        .read(apiClientProvider)
        .get('/diario', parse: (_) => null)
        .ignore();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(storage.session, isNull);
  });
}

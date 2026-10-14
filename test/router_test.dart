import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary/app.dart';
import 'package:mydiary/auth/auth_token.dart';
import 'package:mydiary/config/app_config.dart';
import 'package:mydiary/providers.dart';
import 'package:mydiary/screens/home_screen.dart';
import 'package:mydiary/screens/login_screen.dart';

void main() {
  late ProviderContainer container;

  Future<void> startApp(WidgetTester tester, {String? token}) async {
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig.parse('http://backend.test:9008'),
        ),
      ],
    );
    addTearDown(container.dispose);
    if (token != null) {
      container.read(authTokenProvider.notifier).set(token);
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MyDiaryApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin token muestra el login', (tester) async {
    await startApp(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('con token muestra el inicio', (tester) async {
    await startApp(tester, token: 'abc');

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('al borrarse el token vuelve al login', (tester) async {
    await startApp(tester, token: 'abc');

    container.read(authTokenProvider.notifier).clear();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('al obtener token sale del login', (tester) async {
    await startApp(tester);

    container.read(authTokenProvider.notifier).set('abc');
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}

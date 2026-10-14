import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth/session_notifier.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const home = '/';
  static const login = '/login';
}

/// Mientras se comprueba la sesión, `/splash`; sin sesión, `/login`; con sesión, el resto.
/// Al cerrarse o caducar la sesión, el router se reevalúa y vuelve al login solo.
final routerProvider = Provider<GoRouter>((ref) {
  final sessionChanges = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => sessionChanges.value++);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: sessionChanges,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final location = state.matchedLocation;
      if (session.isLoading && !session.hasValue) {
        return location == Routes.splash ? null : Routes.splash;
      }
      if (session.value == null) {
        return location == Routes.login ? null : Routes.login;
      }
      return location == Routes.login || location == Routes.splash
          ? Routes.home
          : null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    sessionChanges.dispose();
  });

  return router;
});

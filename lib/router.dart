import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_token.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

abstract final class Routes {
  static const home = '/';
  static const login = '/login';
}

/// Sin token, todo lleva a `/login`; con token, `/login` lleva al inicio. Al borrarse el
/// token (logout o `401`), el router se reevalúa y vuelve al login solo.
final routerProvider = Provider<GoRouter>((ref) {
  final tokenChanges = ValueNotifier<String?>(ref.read(authTokenProvider));
  ref.listen(authTokenProvider, (_, token) => tokenChanges.value = token);

  final router = GoRouter(
    initialLocation: Routes.home,
    refreshListenable: tokenChanges,
    redirect: (context, state) {
      final loggedIn = ref.read(authTokenProvider) != null;
      final atLogin = state.matchedLocation == Routes.login;
      if (!loggedIn) {
        return atLogin ? null : Routes.login;
      }
      return atLogin ? Routes.home : null;
    },
    routes: [
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
    tokenChanges.dispose();
  });

  return router;
});

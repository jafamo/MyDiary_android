import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth/session_notifier.dart';
import 'diary/diary_screen.dart';
import 'history/day_screen.dart';
import 'history/history_provider.dart';
import 'history/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/more_screen.dart';
import 'screens/splash_screen.dart';
import 'search/search_screen.dart';
import 'summaries/summaries_screen.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const home = '/';
  static const login = '/login';
  static const history = '/historial';
  static const search = '/buscar';
  static const more = '/mas';
  static const summaries = '$more/resumenes';

  /// Un día del Historial (`/historial/2026-10-14`).
  static String historyDay(DateTime date) => '$history/${formatDayParam(date)}';
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const DiaryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.history,
                builder: (context, state) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':fecha',
                    redirect: (context, state) =>
                        parseDayParam(state.pathParameters['fecha']!) == null
                        ? Routes.history
                        : null,
                    builder: (context, state) => DayScreen(
                      date: parseDayParam(state.pathParameters['fecha']!)!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.search,
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.more,
                builder: (context, state) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'resumenes',
                    builder: (context, state) => const SummariesScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
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

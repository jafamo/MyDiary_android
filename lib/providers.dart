import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'auth/auth_token.dart';
import 'config/app_config.dart';

/// Se sobrescribe en `main()` con la configuración de compilación.
final appConfigProvider = Provider<AppConfig>(
  (ref) =>
      throw UnimplementedError('appConfigProvider se sobrescribe en main()'),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
    token: () => ref.read(authTokenProvider),
    onUnauthorized: () => ref.read(authTokenProvider.notifier).clear(),
  ),
);

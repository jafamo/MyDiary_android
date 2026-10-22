import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'playback/player.dart';
import 'providers.dart';
import 'theme/ui_theme.dart';

Future<void> main() async {
  final AppConfig config;
  try {
    config = AppConfig.fromEnvironment();
  } on ConfigException catch (e) {
    runApp(ConfigErrorApp(message: e.message));
    return;
  }

  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(fontLicenses);
  final player = await startPlayerService();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        playerProvider.overrideWithValue(player),
      ],
      child: const MyDiaryApp(),
    ),
  );
}

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `device_name` del login: identifica el token en `app:user:token:list`.
final deviceNameProvider = FutureProvider<String>((ref) async {
  final info = DeviceInfoPlugin();
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = await info.androidInfo;
      return androidDeviceName(
        android.manufacturer,
        android.model,
        android.version.release,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = await info.iosInfo;
      return iosDeviceName(ios.modelName, ios.systemVersion);
    }
  } on Exception {
    // Sin información del dispositivo: nombre genérico.
  }
  return fallbackDeviceName;
});

const fallbackDeviceName = 'MyDiary app';

/// Máximo que admite el backend.
const deviceNameMaxLength = 100;

/// «Google Pixel 7 (Android 16)». No repite el fabricante si el modelo ya lo lleva.
@visibleForTesting
String androidDeviceName(String manufacturer, String model, String release) {
  final brand = manufacturer.isEmpty
      ? ''
      : manufacturer[0].toUpperCase() + manufacturer.substring(1);
  final name = model.toLowerCase().startsWith(brand.toLowerCase())
      ? model
      : '$brand $model';
  return _finish(name, 'Android $release');
}

/// «iPhone 16 Pro (iOS 19.0)».
@visibleForTesting
String iosDeviceName(String modelName, String systemVersion) =>
    _finish(modelName, 'iOS $systemVersion');

String _finish(String name, String system) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return fallbackDeviceName;
  }
  final full = '$trimmed ($system)';
  return full.length <= deviceNameMaxLength
      ? full
      : full.substring(0, deviceNameMaxLength);
}

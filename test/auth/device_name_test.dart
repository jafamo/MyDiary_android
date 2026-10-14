import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary/auth/device_name.dart';

void main() {
  test('Android: fabricante, modelo y versión', () {
    expect(
      androidDeviceName('google', 'Pixel 7', '16'),
      'Google Pixel 7 (Android 16)',
    );
  });

  test('Android: no repite el fabricante si el modelo ya lo lleva', () {
    expect(
      androidDeviceName('samsung', 'Samsung Galaxy S24', '15'),
      'Samsung Galaxy S24 (Android 15)',
    );
  });

  test('iOS: modelo comercial y versión', () {
    expect(iosDeviceName('iPhone 16 Pro', '19.0'), 'iPhone 16 Pro (iOS 19.0)');
  });

  test('sin modelo: nombre genérico', () {
    expect(iosDeviceName('  ', '19.0'), fallbackDeviceName);
  });

  test('se recorta al máximo del backend', () {
    final name = androidDeviceName('x', 'M' * 200, '16');

    expect(name.length, deviceNameMaxLength);
  });
}

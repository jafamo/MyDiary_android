import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mydiary/format.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  test('día de calendario en español', () {
    expect(formatDay(DateTime(2026, 10, 14)), 'miércoles, 14 de octubre');
  });

  test('hora local de un instante UTC', () {
    final instant = DateTime.utc(2026, 10, 14, 7, 5);
    final local = instant.toLocal();
    final expected =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';

    expect(formatTime(instant), expected);
  });

  test('día y mes locales de un instante UTC', () {
    final instant = DateTime.utc(2026, 3, 5, 12);

    expect(formatShortDate(instant), '05/03');
  });

  test('duración en m:ss', () {
    expect(formatDuration(37), '0:37');
    expect(formatDuration(72), '1:12');
    expect(formatDuration(600), '10:00');
  });

  test('mayúscula inicial y plural', () {
    expect(capitalize('martes'), 'Martes');
    expect(capitalize(''), '');
    expect(plural(1, 'audio', 'audios'), '1 audio');
    expect(plural(3, 'audio', 'audios'), '3 audios');
  });
}

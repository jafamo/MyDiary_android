/// Lectura tipada del JSON de la API. Un campo con un tipo inesperado lanza
/// [FormatException], que `ApiClient` convierte en `invalid_response`.
library;

typedef Json = Map<String, Object?>;

Json asJson(Object? value) {
  if (value is Json) {
    return value;
  }
  throw FormatException(
    'Se esperaba un objeto JSON y llegó ${value.runtimeType}.',
  );
}

final _day = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

extension JsonRead on Json {
  T _read<T>(String key) {
    final value = this[key];
    if (value is T) {
      return value;
    }
    throw FormatException(
      'Campo "$key": se esperaba $T y llegó ${value.runtimeType}.',
    );
  }

  String string(String key) => _read<String>(key);

  String? stringOrNull(String key) => _read<String?>(key);

  int integer(String key) => _read<int>(key);

  int? integerOrNull(String key) => _read<int?>(key);

  bool boolean(String key) => _read<bool>(key);

  Json object(String key) => asJson(this[key]);

  Json? objectOrNull(String key) => this[key] == null ? null : object(key);

  List<T> list<T>(String key, T Function(Json json) item) =>
      _read<List<Object?>>(key).map((e) => item(asJson(e))).toList();

  List<T>? listOrNull<T>(String key, T Function(Json json) item) =>
      this[key] == null ? null : list(key, item);

  /// Instante ISO 8601 en UTC (`2026-10-08T07:09:33Z`). Se pasa a hora local solo al mostrarlo.
  DateTime instant(String key) {
    final value = string(key);
    final parsed = DateTime.tryParse(value);
    if (parsed == null || !parsed.isUtc) {
      throw FormatException('Campo "$key": instante UTC no válido "$value".');
    }
    return parsed;
  }

  DateTime? instantOrNull(String key) =>
      this[key] == null ? null : instant(key);

  /// Día de calendario (`AAAA-MM-DD`, en `Europe/Madrid` en el backend), como medianoche local
  /// y sin conversión de zona: el 5 de octubre es el 5 de octubre en cualquier dispositivo.
  /// No aplicarle nunca `toUtc()` / `toLocal()`.
  DateTime day(String key) {
    final value = string(key);
    final match = _day.firstMatch(value);
    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final dayOfMonth = int.parse(match.group(3)!);
      final date = DateTime(year, month, dayOfMonth);
      if (date.month == month && date.day == dayOfMonth) {
        return date;
      }
    }
    throw FormatException('Campo "$key": día no válido "$value".');
  }

  DateTime? dayOrNull(String key) => this[key] == null ? null : day(key);
}

/// Formato de fechas, horas y duraciones para mostrar. La app solo está en español.
library;

import 'package:intl/intl.dart';

const _locale = 'es';

/// Día de calendario («miércoles, 14 de octubre»), sin conversión de zona (ver `JsonRead.day`).
String formatDay(DateTime day) =>
    DateFormat("EEEE, d 'de' MMMM", _locale).format(day);

/// Hora local (`HH:mm`) de un instante UTC.
String formatTime(DateTime instant) =>
    DateFormat('HH:mm', _locale).format(instant.toLocal());

/// Día y mes locales (`15/10`) de un instante UTC.
String formatShortDate(DateTime instant) =>
    DateFormat('dd/MM', _locale).format(instant.toLocal());

/// Duración en `m:ss`.
String formatDuration(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

String capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// «1 audio», «3 audios».
String plural(int count, String singular, String pluralForm) =>
    '$count ${count == 1 ? singular : pluralForm}';

/// Día de calendario con el año («miércoles, 14 de octubre de 2026»).
String formatDayWithYear(DateTime day) =>
    DateFormat("EEEE, d 'de' MMMM 'de' y", _locale).format(day);

/// Mes de calendario con el año («octubre de 2026»).
String formatMonth(DateTime month) =>
    DateFormat("MMMM 'de' y", _locale).format(month);

/// Día de calendario abreviado con el año («Mié 14 oct 2026»).
String formatShortDay(DateTime day) =>
    capitalize(DateFormat('EEE d MMM y', _locale).format(day));

/// Rango de días («1 mar – 15 mar 2026»; con el año en los dos si cambia).
String formatDayRange(DateTime from, DateTime to) {
  final start = DateFormat(
    from.year == to.year ? 'd MMM' : 'd MMM y',
    _locale,
  ).format(from);
  return '$start – ${DateFormat('d MMM y', _locale).format(to)}';
}

/// Número con separador de miles («3.412»).
String formatNumber(int value) => NumberFormat('#,##0', _locale).format(value);

/// Milisegundos en segundos con un decimal como mucho («38 s», «14,2 s»).
String formatSeconds(int milliseconds) =>
    '${NumberFormat('0.#', _locale).format(milliseconds / 1000)} s';

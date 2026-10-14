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

/// Duración en `m:ss`.
String formatDuration(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

String capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// «1 audio», «3 audios».
String plural(int count, String singular, String pluralForm) =>
    '$count ${count == 1 ? singular : pluralForm}';

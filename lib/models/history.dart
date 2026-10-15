import '../api/json.dart';
import 'audio.dart';
import 'summary.dart';

/// Respuesta de `GET /api/v1/historial`: los días con actividad de un mes.
class HistoryMonth {
  const HistoryMonth({
    required this.month,
    required this.previousMonth,
    required this.nextMonth,
    required this.days,
  });

  factory HistoryMonth.fromJson(Json json) => HistoryMonth(
    month: json.month('month'),
    previousMonth: json.month('previous_month'),
    nextMonth: json.month('next_month'),
    days: json.list('days', ActiveDay.fromJson),
  );

  /// Día 1 del mes. Fecha de calendario (ver `JsonRead.day`).
  final DateTime month;
  final DateTime previousMonth;
  final DateTime nextMonth;

  /// Solo los días con datos.
  final List<ActiveDay> days;
}

class ActiveDay {
  const ActiveDay({
    required this.date,
    required this.audioCount,
    required this.hasSummary,
  });

  factory ActiveDay.fromJson(Json json) => ActiveDay(
    date: json.day('date'),
    audioCount: json.integer('audio_count'),
    hasSummary: json.boolean('has_summary'),
  );

  final DateTime date;
  final int audioCount;
  final bool hasSummary;
}

/// Respuesta de `GET /api/v1/historial/{fecha}`: audios y resumen de un día.
class HistoryDay {
  const HistoryDay({
    required this.date,
    required this.entries,
    this.summary,
    this.previousDate,
    this.nextDate,
  });

  factory HistoryDay.fromJson(Json json) {
    final summary = json.objectOrNull('summary');

    return HistoryDay(
      date: json.day('date'),
      entries: json.list('entries', Audio.fromJson),
      summary: summary == null ? null : Summary.fromJson(summary),
      previousDate: json.dayOrNull('previous_date'),
      nextDate: json.dayOrNull('next_date'),
    );
  }

  final DateTime date;
  final List<Audio> entries;
  final Summary? summary;

  /// Día con audios o resumen más cercano antes y después; `null` si no hay. No dependen del
  /// filtro por estado.
  final DateTime? previousDate;
  final DateTime? nextDate;
}

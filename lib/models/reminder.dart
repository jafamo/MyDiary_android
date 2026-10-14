import '../api/json.dart';

/// Esquema `Reminder`.
class Reminder {
  const Reminder({
    required this.id,
    required this.date,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.time,
  });

  factory Reminder.fromJson(Json json) => Reminder(
    id: json.integer('id'),
    date: json.day('date'),
    time: json.stringOrNull('time'),
    text: json.string('text'),
    createdAt: json.instant('created_at'),
    updatedAt: json.instant('updated_at'),
  );

  final int id;

  /// Día de calendario (ver `JsonRead.day`).
  final DateTime date;

  /// `HH:MM`, o `null` si el recordatorio no tiene hora.
  final String? time;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
}

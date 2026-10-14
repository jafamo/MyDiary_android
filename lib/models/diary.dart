import '../api/json.dart';
import 'audio.dart';
import 'summary.dart';
import 'summary_generation.dart';

/// Respuesta de `GET /api/v1/diario`: la portada de hoy.
class Diary {
  const Diary({
    required this.date,
    required this.entries,
    required this.streak,
    required this.week,
    this.summary,
    this.summaryGeneration,
    this.topTopic,
  });

  factory Diary.fromJson(Json json) {
    final summary = json.objectOrNull('summary');
    final generation = json.objectOrNull('summary_generation');
    final topTopic = json.objectOrNull('top_topic');

    return Diary(
      date: json.day('date'),
      entries: json.list('entries', Audio.fromJson),
      summary: summary == null ? null : Summary.fromJson(summary),
      summaryGeneration: generation == null
          ? null
          : SummaryGeneration.fromJson(generation),
      streak: Streak.fromJson(json.object('streak')),
      week: Week.fromJson(json.object('week')),
      topTopic: topTopic == null ? null : TopTopic.fromJson(topTopic),
    );
  }

  /// Hoy según el backend. Día de calendario (ver `JsonRead.day`).
  final DateTime date;
  final List<Audio> entries;
  final Summary? summary;

  /// Última generación del resumen de hoy, pedida o programada.
  final SummaryGeneration? summaryGeneration;
  final Streak streak;
  final Week week;

  /// Tema más frecuente del mes.
  final TopTopic? topTopic;

  /// Hay algo que el backend todavía está procesando: un audio sin transcribir o el resumen.
  bool get needsPolling =>
      entries.any((e) => e.status == AudioStatus.pending) ||
      (summaryGeneration?.status.inProgress ?? false);
}

class Streak {
  const Streak({required this.current, required this.best});

  factory Streak.fromJson(Json json) =>
      Streak(current: json.integer('current'), best: json.integer('best'));

  /// Días seguidos con audio hasta hoy o ayer.
  final int current;
  final int best;
}

class Week {
  const Week({required this.total, required this.delta});

  factory Week.fromJson(Json json) =>
      Week(total: json.integer('total'), delta: json.integer('delta'));

  /// Audios de esta semana.
  final int total;

  /// Diferencia con la semana anterior.
  final int delta;
}

class TopTopic {
  const TopTopic({required this.name, required this.count});

  factory TopTopic.fromJson(Json json) =>
      TopTopic(name: json.string('name'), count: json.integer('count'));

  final String name;
  final int count;
}

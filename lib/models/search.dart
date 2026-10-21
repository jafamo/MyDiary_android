import '../api/json.dart';
import 'audio.dart';
import 'reminder.dart';
import 'summary.dart';

/// Respuesta de `GET /api/v1/busqueda`.
class SearchResults {
  const SearchResults({
    required this.query,
    required this.results,
    required this.reminders,
  });

  factory SearchResults.fromJson(Json json) => SearchResults(
    query: json.string('query'),
    results: [
      for (final item in json.list('results', SearchResult.fromJson)) ?item,
    ],
    reminders: json.list('reminders', Reminder.fromJson),
  );

  final String query;

  /// Notas y resúmenes, del más parecido al menos parecido (como mucho 20).
  final List<SearchResult> results;

  /// Recordatorios cuyo texto coincide.
  final List<Reminder> reminders;

  bool get isEmpty => results.isEmpty && reminders.isEmpty;
}

/// Una nota o un resumen encontrados.
sealed class SearchResult {
  const SearchResult({required this.date});

  /// `null` si `type` es desconocido: se descarta.
  static SearchResult? fromJson(Json json) => switch (json.string('type')) {
    'transcription' => NoteResult(
      date: json.day('date'),
      audio: Audio.fromJson(json.object('audio')),
    ),
    'daily_summary' => SummaryResult(
      date: json.day('date'),
      summary: Summary.fromJson(json.object('summary')),
    ),
    _ => null,
  };

  /// Día de la nota o del resumen (ver `JsonRead.day`).
  final DateTime date;
}

class NoteResult extends SearchResult {
  const NoteResult({required super.date, required this.audio});

  final Audio audio;
}

class SummaryResult extends SearchResult {
  const SummaryResult({required super.date, required this.summary});

  final Summary summary;
}

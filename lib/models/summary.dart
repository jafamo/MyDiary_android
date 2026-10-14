import '../api/json.dart';
import 'topic.dart';

/// Esquema `Summary` (resumen de un día). Las métricas faltan en los anteriores a su captura.
class Summary {
  const Summary({
    required this.id,
    required this.date,
    required this.summaryText,
    required this.generatedAt,
    required this.topics,
    this.emojiLegend,
    this.model,
    this.promptTokens,
    this.completionTokens,
    this.generationMs,
  });

  factory Summary.fromJson(Json json) => Summary(
    id: json.integer('id'),
    date: json.day('date'),
    summaryText: json.string('summary_text'),
    generatedAt: json.instant('generated_at'),
    emojiLegend: json.listOrNull('emoji_legend', EmojiLegendEntry.fromJson),
    topics: json.list('topics', Topic.fromJson),
    model: json.stringOrNull('model'),
    promptTokens: json.integerOrNull('prompt_tokens'),
    completionTokens: json.integerOrNull('completion_tokens'),
    generationMs: json.integerOrNull('generation_ms'),
  );

  final int id;

  /// Día de calendario (ver `JsonRead.day`).
  final DateTime date;
  final String summaryText;
  final DateTime generatedAt;
  final List<EmojiLegendEntry>? emojiLegend;
  final List<Topic> topics;
  final String? model;
  final int? promptTokens;
  final int? completionTokens;
  final int? generationMs;
}

class EmojiLegendEntry {
  const EmojiLegendEntry({required this.emoji, required this.meaning});

  factory EmojiLegendEntry.fromJson(Json json) => EmojiLegendEntry(
    emoji: json.string('emoji'),
    meaning: json.string('meaning'),
  );

  final String emoji;
  final String meaning;
}

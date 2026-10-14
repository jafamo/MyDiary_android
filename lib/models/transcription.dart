import '../api/json.dart';

/// Esquema `Transcription`. `model` y `processingMs` faltan en las anteriores a su captura.
class Transcription {
  const Transcription({
    required this.id,
    required this.content,
    required this.editedManually,
    required this.createdAt,
    required this.updatedAt,
    this.model,
    this.processingMs,
  });

  factory Transcription.fromJson(Json json) => Transcription(
    id: json.integer('id'),
    content: json.string('content'),
    editedManually: json.boolean('edited_manually'),
    model: json.stringOrNull('model'),
    processingMs: json.integerOrNull('processing_ms'),
    createdAt: json.instant('created_at'),
    updatedAt: json.instant('updated_at'),
  );

  final int id;
  final String content;
  final bool editedManually;
  final String? model;
  final int? processingMs;
  final DateTime createdAt;
  final DateTime updatedAt;
}

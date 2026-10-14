import '../api/json.dart';

enum SummaryGenerationStatus {
  queued,
  running,
  done,
  failed,
  unknown;

  static SummaryGenerationStatus fromJson(String value) => switch (value) {
    'QUEUED' => queued,
    'RUNNING' => running,
    'DONE' => done,
    'FAILED' => failed,
    _ => unknown,
  };

  bool get inProgress => this == queued || this == running;
}

/// Esquema `SummaryGeneration`: estado de la última generación del resumen de un día.
/// Una generación atascada llega como `failed` con `errorCode` `STALLED`.
class SummaryGeneration {
  const SummaryGeneration({
    required this.status,
    required this.requestedAt,
    this.startedAt,
    this.finishedAt,
    this.errorCode,
    this.errorMessage,
  });

  factory SummaryGeneration.fromJson(Json json) => SummaryGeneration(
    status: SummaryGenerationStatus.fromJson(json.string('status')),
    requestedAt: json.instant('requested_at'),
    startedAt: json.instantOrNull('started_at'),
    finishedAt: json.instantOrNull('finished_at'),
    errorCode: json.stringOrNull('error_code'),
    errorMessage: json.stringOrNull('error_message'),
  );

  final SummaryGenerationStatus status;
  final DateTime requestedAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? errorCode;
  final String? errorMessage;
}

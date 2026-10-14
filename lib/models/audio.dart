import '../api/json.dart';
import 'transcription.dart';

enum AudioStatus {
  pending,
  transcribed,
  error,

  /// Valor que esta versión de la app no conoce.
  unknown;

  static AudioStatus fromJson(String value) => switch (value) {
    'PENDING' => pending,
    'TRANSCRIBED' => transcribed,
    'ERROR' => error,
    _ => unknown,
  };
}

enum AudioSource {
  telegram,
  app,
  unknown;

  static AudioSource fromJson(String value) => switch (value) {
    'telegram' => telegram,
    'app' => app,
    _ => unknown,
  };
}

/// Esquema `Audio`. En las respuestas breves (p. ej. la subida) faltan el error y la
/// transcripción, que quedan a `null`.
class Audio {
  const Audio({
    required this.id,
    required this.status,
    required this.source,
    required this.durationSeconds,
    required this.receivedAt,
    this.errorCode,
    this.errorMessage,
    this.transcription,
  });

  factory Audio.fromJson(Json json) {
    final transcription = json.objectOrNull('transcription');

    return Audio(
      id: json.integer('id'),
      status: AudioStatus.fromJson(json.string('status')),
      source: AudioSource.fromJson(json.string('source')),
      durationSeconds: json.integer('duration_seconds'),
      receivedAt: json.instant('received_at'),
      errorCode: json.stringOrNull('error_code'),
      errorMessage: json.stringOrNull('error_message'),
      transcription: transcription == null
          ? null
          : Transcription.fromJson(transcription),
    );
  }

  final int id;
  final AudioStatus status;
  final AudioSource source;
  final int durationSeconds;
  final DateTime receivedAt;
  final String? errorCode;
  final String? errorMessage;
  final Transcription? transcription;
}

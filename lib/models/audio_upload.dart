import '../api/json.dart';
import 'audio.dart';

enum UploadResult {
  /// Audio nuevo, en cola para transcribirse.
  created,

  /// Ya existía (mismo contenido) y no se toca.
  duplicate,

  /// Ya existía con la transcripción fallida y se relanza.
  retrying,

  /// Valor que esta versión de la app no conoce.
  unknown;

  static UploadResult fromJson(String value) => switch (value) {
    'created' => created,
    'duplicate' => duplicate,
    'retrying' => retrying,
    _ => unknown,
  };
}

/// Esquema `AudioUpload`: respuesta de `POST /api/v1/audios`, un `Audio` breve más el resultado.
class AudioUpload {
  const AudioUpload({required this.audio, required this.result});

  factory AudioUpload.fromJson(Json json) => AudioUpload(
    audio: Audio.fromJson(json),
    result: UploadResult.fromJson(json.string('result')),
  );

  final Audio audio;
  final UploadResult result;
}

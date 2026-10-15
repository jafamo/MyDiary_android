import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Grabador de notas de voz. Interfaz para poder probar sin micrófono ni dispositivo.
abstract interface class Recorder {
  /// Pide el permiso del micrófono si hace falta.
  Future<bool> hasPermission();

  /// Empieza a grabar en [path] (AAC-LC `.m4a`).
  Future<void> start(String path);

  Future<void> pause();

  Future<void> resume();

  /// Para y devuelve la ruta del fichero grabado.
  Future<String?> stop();

  /// Para y borra lo grabado.
  Future<void> cancel();

  /// Nivel de entrada en dBFS (0 = máximo, valores negativos por debajo).
  Stream<double> amplitude(Duration interval);

  /// `true` cuando el sistema pausa la grabación por su cuenta (p. ej. una llamada).
  Stream<bool> pausedChanges();

  Future<void> dispose();
}

final recorderProvider = Provider.autoDispose<Recorder>((ref) {
  final recorder = RecordRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
});

/// [Recorder] sobre el paquete `record`. Mientras graba, la pantalla no se apaga.
class RecordRecorder implements Recorder {
  final _recorder = AudioRecorder();

  /// Voz en mono: unos 0,48 MB por minuto.
  static const _config = RecordConfig(
    bitRate: 64000,
    sampleRate: 44100,
    numChannels: 1,
  );

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start(String path) async {
    await _recorder.start(_config, path: path);
    await WakelockPlus.enable();
  }

  @override
  Future<void> pause() async {
    await _recorder.pause();
    await WakelockPlus.disable();
  }

  @override
  Future<void> resume() async {
    await _recorder.resume();
    await WakelockPlus.enable();
  }

  @override
  Future<String?> stop() async {
    await WakelockPlus.disable();
    return _recorder.stop();
  }

  @override
  Future<void> cancel() async {
    await WakelockPlus.disable();
    await _recorder.cancel();
  }

  @override
  Stream<double> amplitude(Duration interval) =>
      _recorder.onAmplitudeChanged(interval).map((a) => a.current);

  @override
  Stream<bool> pausedChanges() =>
      _recorder.onStateChanged().map((state) => state == RecordState.pause);

  @override
  Future<void> dispose() async {
    await WakelockPlus.disable();
    await _recorder.dispose();
  }
}

import 'dart:async';
import 'dart:io';

import 'package:mydiary/recording/recorder.dart';

/// Grabador sin micrófono: escribe un fichero pequeño y deja simular el nivel de entrada
/// y las pausas del sistema.
class FakeRecorder implements Recorder {
  bool permission = true;
  final calls = <String>[];
  String? path;

  final _amplitude = StreamController<double>.broadcast();
  final _paused = StreamController<bool>.broadcast();

  void emitLevel(double dbfs) => _amplitude.add(dbfs);

  /// El sistema pausa la grabación (p. ej. una llamada).
  void systemPause() => _paused.add(true);

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> start(String path) async {
    calls.add('start');
    this.path = path;
    File(path).writeAsBytesSync([0, 1, 2, 3]);
  }

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> resume() async => calls.add('resume');

  @override
  Future<String?> stop() async {
    calls.add('stop');
    return path;
  }

  @override
  Future<void> cancel() async {
    calls.add('cancel');
    final file = File(path!);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  @override
  Stream<double> amplitude(Duration interval) => _amplitude.stream;

  @override
  Stream<bool> pausedChanges() => _paused.stream;

  @override
  Future<void> dispose() async => calls.add('dispose');
}

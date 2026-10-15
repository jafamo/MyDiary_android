import 'dart:async';
import 'dart:io';

import 'package:mydiary/playback/player.dart';

/// Reproductor sin dispositivo: registra las llamadas y emite los cambios de estado como el
/// real. Deja simular el final del audio y los botones de la notificación.
class FakePlayer implements Player {
  Duration duration = const Duration(seconds: 14);
  final calls = <String>[];

  /// Fichero cargado y título de la notificación.
  String? path;
  String? title;

  final _status = StreamController<PlayerStatus>.broadcast();
  final _positions = StreamController<Duration>.broadcast();

  void emitPosition(Duration position) => _positions.add(position);

  /// El audio llega al final.
  void complete() => _status.add(PlayerStatus.completed);

  /// Parar desde la notificación.
  void stopFromNotification() {
    calls.add('stop');
    _status.add(PlayerStatus.idle);
  }

  @override
  Future<Duration?> load(
    String path, {
    required String id,
    required String title,
  }) async {
    calls.add('load');
    if (!File(path).existsSync()) {
      throw StateError('No existe $path');
    }
    this.path = path;
    this.title = title;
    return duration;
  }

  @override
  Future<void> play() async {
    calls.add('play');
    _status.add(PlayerStatus.playing);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _status.add(PlayerStatus.paused);
  }

  @override
  Future<void> seek(Duration position) async => calls.add('seek $position');

  @override
  Future<void> setSpeed(double speed) async => calls.add('speed $speed');

  @override
  Future<void> stop() async {
    calls.add('stop');
    _status.add(PlayerStatus.idle);
  }

  @override
  Stream<PlayerStatus> get statusChanges => _status.stream;

  @override
  Stream<Duration> get positions => _positions.stream;
}

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

enum PlayerStatus {
  /// Sin audio cargado o parado (también desde la notificación).
  idle,
  playing,
  paused,

  /// Ha llegado al final.
  completed,
}

/// Reproductor de notas. Interfaz para poder probar sin dispositivo.
abstract interface class Player {
  /// Carga el fichero local [path] y devuelve su duración. [title] sale en la notificación
  /// y en la pantalla de bloqueo.
  Future<Duration?> load(
    String path, {
    required String id,
    required String title,
  });

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> setSpeed(double speed);

  Future<void> stop();

  /// Cambios de estado, también los que llegan de la notificación.
  Stream<PlayerStatus> get statusChanges;

  Stream<Duration> get positions;
}

/// Se sobrescribe en `main()` con el handler de `AudioService.init`; los tests, con un doble.
final playerProvider = Provider<Player>(
  (ref) => throw UnimplementedError('playerProvider se sobrescribe en main()'),
);

/// Inicia el servicio de reproducción en segundo plano. Solo se puede llamar una vez.
Future<Player> startPlayerService() => AudioService.init<ServicePlayer>(
  builder: ServicePlayer.new,
  config: const AudioServiceConfig(
    androidNotificationChannelId: 'com.jfarinos.mydiary.playback',
    androidNotificationChannelName: 'Reproducción',
    androidStopForegroundOnPause: true,
  ),
);

/// [Player] sobre `just_audio`, publicado con `audio_service` para que siga sonando fuera de
/// la app y tenga controles en la notificación y en la pantalla de bloqueo.
class ServicePlayer extends BaseAudioHandler
    with SeekHandler
    implements Player {
  ServicePlayer() {
    _player.playbackEventStream.listen((_) => _broadcast());
    _player.playingStream.listen((_) => _broadcast());
  }

  final _player = AudioPlayer();

  @override
  Future<Duration?> load(
    String path, {
    required String id,
    required String title,
  }) async {
    final duration = await _player.setFilePath(path);
    mediaItem.add(MediaItem(id: id, title: title, duration: duration));
    return duration;
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> stop() async {
    await _player.stop();
    mediaItem.add(null);
  }

  @override
  Stream<PlayerStatus> get statusChanges => _player.playerStateStream
      .map(
        (state) => switch (state.processingState) {
          ProcessingState.idle => PlayerStatus.idle,
          ProcessingState.completed => PlayerStatus.completed,
          _ => state.playing ? PlayerStatus.playing : PlayerStatus.paused,
        },
      )
      .distinct();

  @override
  Stream<Duration> get positions => _player.positionStream;

  /// Estado para la notificación y la pantalla de bloqueo.
  void _broadcast() {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.fastForward,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }
}

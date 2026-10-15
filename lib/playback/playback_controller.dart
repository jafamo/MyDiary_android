import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import '../format.dart';
import '../models/audio.dart';
import '../providers.dart';
import 'player.dart';

enum PlaybackPhase { downloading, playing, paused }

/// Nota que se está escuchando, si hay alguna.
class NotePlayback {
  const NotePlayback({
    this.audioId,
    this.phase = PlaybackPhase.downloading,
    this.progress,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1,
    this.error,
  });

  final int? audioId;
  final PlaybackPhase phase;

  /// Fracción descargada, o `null` si aún no se sabe el total.
  final double? progress;

  final Duration position;
  final Duration duration;
  final double speed;

  /// Por qué no se ha podido escuchar la última nota pedida, para avisar una vez.
  final String? error;

  NotePlayback copyWith({
    PlaybackPhase? phase,
    double? Function()? progress,
    Duration? position,
    Duration? duration,
    double? speed,
  }) => NotePlayback(
    audioId: audioId,
    phase: phase ?? this.phase,
    progress: progress == null ? this.progress : progress(),
    position: position ?? this.position,
    duration: duration ?? this.duration,
    speed: speed ?? this.speed,
  );
}

final playbackControllerProvider =
    NotifierProvider<PlaybackController, NotePlayback>(PlaybackController.new);

/// Escuchar una nota: se descarga entera con el token, se reproduce desde el fichero local
/// y el fichero se borra al terminar. Vive mientras la app, porque suena en segundo plano.
class PlaybackController extends Notifier<NotePlayback> {
  static const speeds = [1.0, 1.5, 2.0];

  late Player _player;

  /// Descarga o reproducción en curso; cambia al pedir otra nota.
  CancelToken? _session;

  /// Fichero de la nota cargada en el reproductor.
  String? _path;

  @override
  NotePlayback build() {
    _player = ref.watch(playerProvider);
    final status = _player.statusChanges.listen(_onStatus);
    final positions = _player.positions.listen(_onPosition);
    ref.onDispose(() {
      unawaited(status.cancel());
      unawaited(positions.cancel());
      _session?.cancel();
    });
    return const NotePlayback();
  }

  /// Escuchar [audio], o pausarla, continuarla o cancelar su descarga si ya es la actual.
  Future<void> toggle(Audio audio) async {
    if (state.audioId == audio.id) {
      switch (state.phase) {
        case PlaybackPhase.downloading:
          await stop();
        case PlaybackPhase.playing:
          await _player.pause();
        case PlaybackPhase.paused:
          // `play` termina cuando deja de sonar: no se espera.
          unawaited(_player.play());
      }
      return;
    }
    await _release();

    final session = CancelToken();
    _session = session;
    state = NotePlayback(audioId: audio.id, speed: state.speed);
    try {
      final directory = await ref.read(temporaryDirectoryProvider.future);
      _deleteLeftovers(directory);
      final download = '${directory.path}/escucha-${audio.id}';
      final contentType = await ref
          .read(apiClientProvider)
          .download(
            '/audios/${audio.id}/fichero',
            download,
            cancelToken: session,
            onReceiveProgress: (received, total) {
              if (total > 0 && identical(_session, session)) {
                state = state.copyWith(progress: () => received / total);
              }
            },
          );
      if (!identical(_session, session)) {
        _delete(download);
        return;
      }
      // AVPlayer reconoce el formato por la extensión.
      final path = '$download.${_extension(contentType)}';
      File(download).renameSync(path);
      _path = path;

      final duration = await _player.load(
        path,
        id: '${audio.id}',
        title:
            'Nota del ${formatShortDate(audio.receivedAt)} '
            '${formatTime(audio.receivedAt)}',
      );
      if (!identical(_session, session)) {
        return;
      }
      await _player.setSpeed(state.speed);
      state = state.copyWith(
        phase: PlaybackPhase.playing,
        progress: () => null,
        duration: duration ?? Duration(seconds: audio.durationSeconds),
      );
      unawaited(_player.play());
    } on ApiException catch (e) {
      if (e.code != ApiException.cancelled && identical(_session, session)) {
        _session = null;
        state = NotePlayback(speed: state.speed, error: e.message);
      }
    }
  }

  /// Para la nota actual (o su descarga) y borra su fichero.
  Future<void> stop() => _release();

  /// Pausa lo que esté sonando (p. ej. al empezar a grabar).
  Future<void> pause() async {
    if (state.phase == PlaybackPhase.playing && _path != null) {
      await _player.pause();
    }
  }

  Future<void> seek(Duration position) async {
    if (_path == null) {
      return;
    }
    state = state.copyWith(position: position);
    await _player.seek(position);
  }

  /// 1× → 1,5× → 2× → 1×.
  Future<void> cycleSpeed() async {
    final next = speeds[(speeds.indexOf(state.speed) + 1) % speeds.length];
    state = state.copyWith(speed: next);
    if (_path != null) {
      await _player.setSpeed(next);
    }
  }

  Future<void> _release() async {
    _session?.cancel();
    _session = null;
    final path = _path;
    _path = null;
    if (state.audioId != null) {
      state = NotePlayback(speed: state.speed);
    }
    if (path != null) {
      await _player.stop();
      _delete(path);
    }
  }

  void _onStatus(PlayerStatus status) {
    if (_path == null) {
      return;
    }
    switch (status) {
      // Al acabar o al parar desde la notificación.
      case PlayerStatus.idle || PlayerStatus.completed:
        unawaited(_release());
      case PlayerStatus.playing:
        state = state.copyWith(phase: PlaybackPhase.playing);
      case PlayerStatus.paused:
        state = state.copyWith(phase: PlaybackPhase.paused);
    }
  }

  void _onPosition(Duration position) {
    if (_path != null) {
      state = state.copyWith(
        position: position > state.duration ? state.duration : position,
      );
    }
  }

  static String _extension(String? contentType) =>
      switch (contentType?.split(';').first.trim()) {
        'audio/ogg' => 'ogg',
        'audio/mpeg' => 'mp3',
        'audio/wav' || 'audio/x-wav' => 'wav',
        _ => 'm4a',
      };

  static void _delete(String path) {
    final file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  /// Ficheros de escucha que quedaron, p. ej. si se cerró la app sonando.
  static void _deleteLeftovers(Directory directory) {
    for (final entity in directory.listSync()) {
      if (entity is File &&
          entity.uri.pathSegments.last.startsWith('escucha-')) {
        entity.deleteSync();
      }
    }
  }
}

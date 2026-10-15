import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import '../api/json.dart';
import '../models/audio_upload.dart';
import '../playback/playback_controller.dart';
import '../providers.dart';
import 'recorder.dart';

enum RecordingPhase {
  /// Pidiendo permiso y preparando el fichero.
  starting,
  noPermission,
  recording,
  paused,
  uploading,

  /// La subida ha fallado; el fichero se conserva para reintentar.
  failed,

  /// Subida terminada o nota descartada: la hoja se cierra.
  done,
}

class RecordingState {
  const RecordingState({
    this.phase = RecordingPhase.starting,
    this.elapsed = Duration.zero,
    this.levels = const [],
    this.limitReached = false,
    this.progress,
    this.error,
    this.upload,
  });

  final RecordingPhase phase;
  final Duration elapsed;

  /// Últimos niveles de entrada, de 0 (silencio) a 1.
  final List<double> levels;

  /// Se ha llegado a [RecordingController.maxDuration]: solo queda enviar o descartar.
  final bool limitReached;

  /// Fracción enviada durante la subida, o `null` si aún no se sabe el total.
  final double? progress;

  final String? error;

  /// Resultado de la subida, cuando ha ido bien.
  final AudioUpload? upload;

  bool get canSend =>
      (phase == RecordingPhase.recording || phase == RecordingPhase.paused) &&
      elapsed >= RecordingController.minDuration;

  /// Hay una nota que se perdería al cerrar la hoja.
  bool get hasContent => switch (phase) {
    RecordingPhase.recording ||
    RecordingPhase.paused ||
    RecordingPhase.uploading ||
    RecordingPhase.failed => true,
    _ => false,
  };

  RecordingState copyWith({
    RecordingPhase? phase,
    Duration? elapsed,
    List<double>? levels,
    bool? limitReached,
    double? Function()? progress,
    String? Function()? error,
    AudioUpload? upload,
  }) => RecordingState(
    phase: phase ?? this.phase,
    elapsed: elapsed ?? this.elapsed,
    levels: levels ?? this.levels,
    limitReached: limitReached ?? this.limitReached,
    progress: progress == null ? this.progress : progress(),
    error: error == null ? this.error : error(),
    upload: upload ?? this.upload,
  );
}

final recordingControllerProvider =
    NotifierProvider.autoDispose<RecordingController, RecordingState>(
      RecordingController.new,
    );

/// Una nota de voz: grabarla, pausarla y subirla. Sin cola (D6): si la hoja se cierra
/// sin subirla, la grabación se pierde.
class RecordingController extends Notifier<RecordingState> {
  /// Unos 22 MB a 64 kbps, por debajo de los 25 MB que admite el backend.
  static const maxDuration = Duration(minutes: 45);

  /// Por debajo, un toque accidental: el backend rechazaría el fichero.
  static const minDuration = Duration(seconds: 1);

  static const levelInterval = Duration(milliseconds: 150);
  static const maxLevels = 40;

  late Recorder _recorder;
  String? _path;
  Timer? _ticker;
  StreamSubscription<double>? _amplitude;
  StreamSubscription<bool>? _paused;

  @override
  RecordingState build() {
    _recorder = ref.watch(recorderProvider);
    ref.onDispose(_dispose);
    return const RecordingState();
  }

  Future<void> start() async {
    // No se graba encima de una nota que está sonando.
    await ref.read(playbackControllerProvider.notifier).pause();
    if (!await _recorder.hasPermission()) {
      state = state.copyWith(phase: RecordingPhase.noPermission);
      return;
    }
    final directory = await ref.read(temporaryDirectoryProvider.future);
    _deleteLeftovers(directory);
    final path =
        '${directory.path}/nota-${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(path);
    _path = path;

    _amplitude = _recorder.amplitude(levelInterval).listen(_addLevel);
    _paused = _recorder.pausedChanges().listen((paused) {
      // El sistema la ha pausado por su cuenta (p. ej. una llamada).
      if (paused && state.phase == RecordingPhase.recording) {
        _stopTicker();
        state = state.copyWith(phase: RecordingPhase.paused);
      }
    });
    _startTicker();
    state = state.copyWith(phase: RecordingPhase.recording);
  }

  Future<void> pause() async {
    if (state.phase != RecordingPhase.recording) {
      return;
    }
    _stopTicker();
    state = state.copyWith(phase: RecordingPhase.paused);
    await _recorder.pause();
  }

  Future<void> resume() async {
    if (state.phase != RecordingPhase.paused || state.limitReached) {
      return;
    }
    await _recorder.resume();
    _startTicker();
    state = state.copyWith(phase: RecordingPhase.recording);
  }

  Future<void> send() async {
    if (!state.canSend) {
      return;
    }
    _stopTicker();
    _stopListening();
    _path = await _recorder.stop() ?? _path;
    await _upload();
  }

  Future<void> retry() async {
    if (state.phase == RecordingPhase.failed) {
      await _upload();
    }
  }

  Future<void> discard() async {
    final wasRecording =
        state.phase == RecordingPhase.recording ||
        state.phase == RecordingPhase.paused;
    _stopTicker();
    _stopListening();
    if (wasRecording) {
      await _recorder.cancel();
    }
    _deleteFile();
    state = state.copyWith(phase: RecordingPhase.done);
  }

  Future<void> _upload() async {
    final path = _path;
    if (path == null) {
      return;
    }
    state = state.copyWith(
      phase: RecordingPhase.uploading,
      progress: () => null,
      error: () => null,
    );
    try {
      final upload = await ref
          .read(apiClientProvider)
          .post(
            '/audios',
            body: FormData.fromMap({
              'file': MultipartFile.fromFileSync(path, filename: 'nota.m4a'),
            }),
            parse: (json) => AudioUpload.fromJson(asJson(json)),
            onSendProgress: (sent, total) {
              if (total > 0 && ref.mounted) {
                state = state.copyWith(progress: () => sent / total);
              }
            },
          );
      _deleteFile();
      if (ref.mounted) {
        state = state.copyWith(phase: RecordingPhase.done, upload: upload);
      }
    } on ApiException catch (e) {
      _fail(e.message);
    } on FileSystemException {
      _fail('No se encuentra la grabación.');
    }
  }

  void _fail(String message) {
    if (ref.mounted) {
      state = state.copyWith(
        phase: RecordingPhase.failed,
        error: () => message,
      );
    }
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = state.elapsed + const Duration(seconds: 1);
      if (elapsed >= maxDuration) {
        _stopTicker();
        state = state.copyWith(
          phase: RecordingPhase.paused,
          elapsed: maxDuration,
          limitReached: true,
        );
        unawaited(_recorder.pause());
        return;
      }
      state = state.copyWith(elapsed: elapsed);
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _addLevel(double dbfs) {
    if (state.phase != RecordingPhase.recording) {
      return;
    }
    // -60 dBFS o menos cuenta como silencio.
    final level = ((dbfs + 60) / 60).clamp(0.0, 1.0);
    final levels = [...state.levels, level];
    state = state.copyWith(
      levels: levels.length > maxLevels
          ? levels.sublist(levels.length - maxLevels)
          : levels,
    );
  }

  void _stopListening() {
    unawaited(_amplitude?.cancel());
    unawaited(_paused?.cancel());
    _amplitude = null;
    _paused = null;
  }

  void _deleteFile() {
    final path = _path;
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    _path = null;
  }

  /// Notas de una sesión anterior que no se llegaron a subir. Sin cola, no tienen uso.
  void _deleteLeftovers(Directory directory) {
    for (final entity in directory.listSync()) {
      final name = entity.uri.pathSegments.last;
      if (entity is File && name.startsWith('nota-') && name.endsWith('.m4a')) {
        entity.deleteSync();
      }
    }
  }

  /// Al cerrar la hoja. `recorderProvider` libera el grabador, que para lo que esté grabando.
  void _dispose() {
    _stopTicker();
    _stopListening();
    _deleteFile();
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/audio_upload.dart';
import 'recording_controller.dart';

/// Abre la hoja y empieza a grabar. Devuelve el resultado de la subida, o `null` si se
/// descarta o no hay permiso.
Future<AudioUpload?> showRecordingSheet(BuildContext context) =>
    showModalBottomSheet<AudioUpload>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const RecordingSheet(),
    );

String uploadMessage(UploadResult result) => switch (result) {
  UploadResult.duplicate => 'Esta nota ya estaba subida.',
  UploadResult.retrying =>
    'Esta nota ya estaba subida. Se vuelve a transcribir.',
  _ => 'Nota enviada. Se está transcribiendo.',
};

class RecordingSheet extends ConsumerStatefulWidget {
  const RecordingSheet({super.key});

  @override
  ConsumerState<RecordingSheet> createState() => _RecordingSheetState();
}

class _RecordingSheetState extends ConsumerState<RecordingSheet> {
  late final AppLifecycleListener _lifecycle;

  RecordingController get _controller =>
      ref.read(recordingControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    // Fuera de la app, Android corta el micrófono: se pausa y se conserva lo grabado.
    _lifecycle = AppLifecycleListener(onHide: () => _controller.pause());
    unawaited(Future.microtask(() => _controller.start()));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _confirmDiscard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar la nota?'),
        content: const Text('Se borrará lo grabado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _controller.discard();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(recordingControllerProvider, (_, next) {
      if (next.phase == RecordingPhase.done) {
        Navigator.of(context).pop(next.upload);
      }
    });
    final state = ref.watch(recordingControllerProvider);

    return PopScope(
      canPop: !state.hasContent,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && state.phase != RecordingPhase.uploading) {
          unawaited(_confirmDiscard());
        }
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: switch (state.phase) {
            RecordingPhase.starting || RecordingPhase.done => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
            RecordingPhase.noPermission => _NoPermission(
              onClose: () => Navigator.of(context).pop(),
            ),
            RecordingPhase.recording || RecordingPhase.paused => _Recording(
              state: state,
              onDiscard: _confirmDiscard,
              onPause: _controller.pause,
              onResume: _controller.resume,
              onSend: _controller.send,
            ),
            RecordingPhase.uploading => _Uploading(progress: state.progress),
            RecordingPhase.failed => _Failed(
              error: state.error ?? '',
              onDiscard: _confirmDiscard,
              onRetry: _controller.retry,
            ),
          },
        ),
      ),
    );
  }
}

String _clock(Duration elapsed) {
  final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
  final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _Recording extends StatelessWidget {
  const _Recording({
    required this.state,
    required this.onDiscard,
    required this.onPause,
    required this.onResume,
    required this.onSend,
  });

  final RecordingState state;
  final VoidCallback onDiscard;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recording = state.phase == RecordingPhase.recording;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.circle,
              size: 12,
              color: recording ? Colors.red : theme.colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Text(
              recording ? 'Grabando' : 'En pausa',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(width: 16),
            Text(
              _clock(state.elapsed),
              style: theme.textTheme.titleMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _LevelBars(levels: state.levels),
        if (state.limitReached) ...[
          const SizedBox(height: 12),
          Text(
            'Has llegado al máximo de 45 min.',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: onDiscard,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Descartar'),
            ),
            if (recording)
              FilledButton.tonalIcon(
                onPressed: onPause,
                icon: const Icon(Icons.pause),
                label: const Text('Pausa'),
              )
            else
              FilledButton.tonalIcon(
                onPressed: state.limitReached ? null : onResume,
                icon: const Icon(Icons.mic),
                label: const Text('Continuar'),
              ),
            FilledButton.icon(
              onPressed: state.canSend ? onSend : null,
              icon: const Icon(Icons.send),
              label: const Text('Enviar'),
            ),
          ],
        ),
      ],
    );
  }
}

class _LevelBars extends StatelessWidget {
  const _LevelBars({required this.levels});

  final List<double> levels;

  static const _height = 48.0;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final padded = [
      ...List.filled(RecordingController.maxLevels - levels.length, 0.0),
      ...levels,
    ];

    return SizedBox(
      height: _height,
      child: Row(
        children: [
          for (final level in padded)
            Expanded(
              child: Center(
                child: Container(
                  width: 3,
                  height: 3 + level * (_height - 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Uploading extends StatelessWidget {
  const _Uploading({required this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Enviando…'),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({
    required this.error,
    required this.onDiscard,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onDiscard;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off, size: 40, color: colors.error),
        const SizedBox(height: 12),
        Text(error, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        const Text(
          'La nota se conserva mientras no cierres la app.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: onDiscard,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Descartar'),
            ),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ],
    );
  }
}

class _NoPermission extends StatelessWidget {
  const _NoPermission({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mic_off, size: 40),
        const SizedBox(height: 12),
        const Text(
          'MyDiary necesita el micrófono para grabar. '
          'Actívalo en los ajustes del sistema.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextButton(onPressed: onClose, child: const Text('Cerrar')),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../format.dart';
import '../models/audio.dart';
import 'playback_controller.dart';

/// Botón de escuchar de una entrada: ▶, progreso de la descarga (toque = cancelar) o ⏸.
class PlayButton extends ConsumerWidget {
  const PlayButton({super.key, required this.audio});

  final Audio audio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(
      playbackControllerProvider.select(
        (p) => p.audioId == audio.id ? (p.phase, p.progress) : null,
      ),
    );
    final (tooltip, icon) = switch (current) {
      null => ('Escuchar', const Icon(Icons.play_arrow)),
      (PlaybackPhase.downloading, final progress) => (
        'Cancelar',
        SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(value: progress, strokeWidth: 2),
        ),
      ),
      (PlaybackPhase.playing, _) => ('Pausa', const Icon(Icons.pause)),
      (PlaybackPhase.paused, _) => ('Continuar', const Icon(Icons.play_arrow)),
    };

    return IconButton(
      onPressed: () =>
          ref.read(playbackControllerProvider.notifier).toggle(audio),
      tooltip: tooltip,
      icon: icon,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Barra de progreso, tiempo y velocidad de la entrada que se está escuchando. Vacía en el
/// resto.
class NotePlayerBar extends ConsumerStatefulWidget {
  const NotePlayerBar({super.key, required this.audio});

  final Audio audio;

  @override
  ConsumerState<NotePlayerBar> createState() => _NotePlayerBarState();
}

class _NotePlayerBarState extends ConsumerState<NotePlayerBar> {
  /// Posición mientras se arrastra la barra; el salto se hace al soltarla.
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackControllerProvider);
    if (playback.audioId != widget.audio.id ||
        playback.phase == PlaybackPhase.downloading) {
      return const SizedBox.shrink();
    }
    final controller = ref.read(playbackControllerProvider.notifier);
    final max = playback.duration.inMilliseconds.toDouble();
    final value = (_dragging ?? playback.position.inMilliseconds.toDouble())
        .clamp(0.0, max);

    return Row(
      children: [
        Expanded(
          child: Slider(
            value: value,
            max: max > 0 ? max : 1,
            onChanged: (v) => setState(() => _dragging = v),
            onChangeEnd: (v) {
              setState(() => _dragging = null);
              controller.seek(Duration(milliseconds: v.round()));
            },
          ),
        ),
        Text(
          '${formatDuration(value ~/ 1000)} / '
          '${formatDuration(playback.duration.inSeconds)}',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        TextButton(
          onPressed: controller.cycleSpeed,
          child: Text(speedLabel(playback.speed)),
        ),
      ],
    );
  }
}

/// `1×`, `1,5×`, `2×`.
String speedLabel(double speed) =>
    '${speed == speed.roundToDouble() ? speed.toInt() : speed.toString().replaceAll('.', ',')}×';

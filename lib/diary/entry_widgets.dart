/// Piezas comunes del Diario y del día del Historial.
library;

import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../format.dart';
import '../models/audio.dart';
import '../models/summary.dart';
import '../models/summary_generation.dart';
import '../playback/note_player.dart';

/// `message` de la API o un texto genérico.
String errorMessage(Object? error) =>
    error is ApiException ? error.message : 'Error inesperado.';

class LoadError extends StatelessWidget {
  const LoadError({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(errorMessage(error), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class RefreshErrorBanner extends StatelessWidget {
  const RefreshErrorBanner({super.key, required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.sync_problem, color: colors.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No se pudo actualizar. ${errorMessage(error)}',
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.summary,
    this.generation,
    required this.emptyText,
  });

  final Summary? summary;
  final SummaryGeneration? generation;

  /// Lo que se muestra si no hay resumen ni generación en curso.
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    final status = _GenerationStatus.of(generation);

    if (summary == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: status ?? Text(emptyText),
        ),
      );
    }

    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        leading: Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
        title: Text('Resumen del día · ${formatTime(summary.generatedAt)}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status != null) ...[status, const SizedBox(height: 8)],
          Text(summary.summaryText),
          SummaryExtras(summary: summary),
        ],
      ),
    );
  }
}

/// Leyenda de emojis y temas de un resumen (nada si no tiene).
class SummaryExtras extends StatelessWidget {
  const SummaryExtras({super.key, required this.summary});

  final Summary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final legend = summary.emojiLegend ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (legend.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final item in legend)
                Text(
                  '${item.emoji} ${item.meaning}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ],
        if (summary.topics.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final topic in summary.topics)
                Chip(
                  avatar: const Icon(Icons.sell_outlined, size: 16),
                  label: Text(topic.name),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Estado de la última generación del resumen, si está en curso o ha fallado.
class _GenerationStatus extends StatelessWidget {
  const _GenerationStatus._(this.generation);

  static _GenerationStatus? of(SummaryGeneration? generation) {
    final status = generation?.status;
    return status != null &&
            (status.inProgress || status == SummaryGenerationStatus.failed)
        ? _GenerationStatus._(generation!)
        : null;
  }

  final SummaryGeneration generation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (generation.status.inProgress) {
      return const Row(
        children: [
          Icon(Icons.schedule, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text('Generando el resumen…')),
        ],
      );
    }
    final at = formatTime(generation.finishedAt ?? generation.requestedAt);
    return Row(
      children: [
        Icon(Icons.error_outline, size: 18, color: colors.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'No se pudo generar el resumen ($at)',
            style: TextStyle(color: colors.error),
          ),
        ),
      ],
    );
  }
}

class StatusFilter extends StatelessWidget {
  const StatusFilter({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AudioStatus? selected;
  final ValueChanged<AudioStatus?> onSelected;

  static const _options = [
    (null, 'Todos'),
    (AudioStatus.pending, 'Pendiente'),
    (AudioStatus.transcribed, 'Transcrito'),
    (AudioStatus.error, 'Error'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final (status, label) in _options)
          ChoiceChip(
            label: Text(label),
            selected: selected == status,
            onSelected: (_) => onSelected(status),
          ),
      ],
    );
  }
}

class EntryCard extends StatelessWidget {
  const EntryCard({super.key, required this.audio});

  final Audio audio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final transcription = audio.transcription;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PlayButton(audio: audio),
                const SizedBox(width: 4),
                Text(
                  '${formatTime(audio.receivedAt)} · '
                  '${formatDuration(audio.durationSeconds)}',
                  style: muted,
                ),
                const Spacer(),
                _StatusLabel(status: audio.status),
              ],
            ),
            NotePlayerBar(audio: audio),
            const SizedBox(height: 8),
            switch (audio.status) {
              AudioStatus.transcribed when transcription != null =>
                _ExpandableText(transcription.content),
              AudioStatus.pending => Text(
                'Transcripción en curso…',
                style: muted,
              ),
              AudioStatus.error => Text(
                audio.errorMessage ?? 'Error en la transcripción',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              _ => const SizedBox.shrink(),
            },
          ],
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final AudioStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, label, color) = switch (status) {
      AudioStatus.transcribed => (
        Icons.check_circle_outline,
        'Transcrito',
        colors.primary,
      ),
      AudioStatus.pending => (
        Icons.hourglass_top,
        'Transcribiendo…',
        colors.onSurfaceVariant,
      ),
      AudioStatus.error => (Icons.error_outline, 'Error', colors.error),
      AudioStatus.unknown => (
        Icons.help_outline,
        'Desconocido',
        colors.onSurfaceVariant,
      ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

/// Texto plegado a [maxLines] con «Ver más» si no cabe.
class _ExpandableText extends StatefulWidget {
  const _ExpandableText(this.text);

  static const maxLines = 4;

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _ExpandableText.maxLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              maxLines: _expanded ? null : _ExpandableText.maxLines,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
            if (overflows)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'Ver menos' : 'Ver más'),
                ),
              ),
          ],
        );
      },
    );
  }
}

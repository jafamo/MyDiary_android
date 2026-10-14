import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import '../format.dart';
import '../models/audio.dart';
import '../models/diary.dart';
import '../models/summary.dart';
import '../models/summary_generation.dart';
import '../screens/account_menu.dart';
import 'diary_provider.dart';

/// Portada: el Diario de hoy.
class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  /// Cada cuánto se recarga mientras el backend procesa algo (el mismo que la web).
  static const pollInterval = Duration(seconds: 10);

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  late final AppLifecycleListener _lifecycle;
  bool _foreground = true;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) =>
          _foreground = state == AppLifecycleState.resumed,
      onResume: () => ref.invalidate(diaryProvider),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  /// Programa la siguiente recarga si el backend sigue procesando algo de lo visible.
  void _schedulePoll(Diary? diary) {
    _poll?.cancel();
    _poll = (diary?.needsPolling ?? false)
        ? Timer(DiaryScreen.pollInterval, _onPoll)
        : null;
  }

  void _onPoll() {
    if (!mounted || !_foreground) {
      // Al volver a primer plano se recarga igualmente.
      return;
    }
    if (!TickerMode.valuesOf(context).enabled) {
      // Pestaña oculta: se vuelve a mirar más tarde sin pedir nada.
      _schedulePoll(ref.read(diaryProvider).value);
      return;
    }
    ref.invalidate(diaryProvider);
  }

  Future<void> _refresh() async {
    try {
      ref.invalidate(diaryProvider);
      await ref.read(diaryProvider.future);
    } on Object {
      // El error se muestra en la pantalla.
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(diaryProvider, (_, next) {
      if (!next.isLoading) {
        _schedulePoll(next.value);
      }
    });
    final diary = ref.watch(diaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diario'),
        actions: const [AccountMenu()],
        bottom: diary.isLoading && diary.hasValue
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: switch (diary) {
        AsyncValue(:final value?) => RefreshIndicator(
          onRefresh: _refresh,
          child: _DiaryView(
            diary: value,
            refreshError: diary.hasError ? diary.error : null,
          ),
        ),
        AsyncError(:final error) => _LoadError(
          error: error,
          onRetry: () => ref.invalidate(diaryProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

String _errorMessage(Object? error) =>
    error is ApiException ? error.message : 'Error inesperado.';

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

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
            Text(_errorMessage(error), textAlign: TextAlign.center),
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

class _DiaryView extends ConsumerWidget {
  const _DiaryView({required this.diary, this.refreshError});

  final Diary diary;

  /// Error de la última recarga; los datos son los anteriores.
  final Object? refreshError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(diaryFilterProvider);
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (refreshError != null) ...[
          _RefreshErrorBanner(error: refreshError),
          const SizedBox(height: 12),
        ],
        Text(
          capitalize(formatDay(diary.date)),
          style: theme.textTheme.titleLarge,
        ),
        Text(
          plural(diary.entries.length, 'audio', 'audios'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _Stats(diary: diary),
        const SizedBox(height: 12),
        _SummaryCard(
          summary: diary.summary,
          generation: diary.summaryGeneration,
        ),
        const SizedBox(height: 12),
        _StatusFilter(selected: filter),
        const SizedBox(height: 8),
        if (diary.entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              filter == null
                  ? 'Sin audios hoy.'
                  : 'Ningún audio con este estado.',
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final entry in diary.entries)
            _EntryCard(key: ValueKey(entry.id), audio: entry),
      ],
    );
  }
}

class _RefreshErrorBanner extends StatelessWidget {
  const _RefreshErrorBanner({required this.error});

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
              'No se pudo actualizar. ${_errorMessage(error)}',
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.diary});

  final Diary diary;

  @override
  Widget build(BuildContext context) {
    final week = diary.week;
    final topic = diary.topTopic;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Stat(
            icon: Icons.local_fire_department,
            value: plural(diary.streak.current, 'día', 'días'),
            foot: 'mejor: ${diary.streak.best}',
          ),
        ),
        Expanded(
          child: _Stat(
            icon: Icons.mic,
            value: '${week.total} esta semana',
            foot: switch (week.delta) {
              > 0 => '+${week.delta} vs. anterior',
              < 0 => '−${-week.delta} vs. anterior',
              _ => 'igual que la anterior',
            },
          ),
        ),
        Expanded(
          child: _Stat(
            icon: Icons.sell,
            value: topic?.name ?? '—',
            foot: topic == null
                ? 'sin resúmenes este mes'
                : plural(topic.count, 'mención', 'menciones'),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.foot});

  final IconData icon;
  final String value;
  final String foot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            foot,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.generation});

  final Summary? summary;
  final SummaryGeneration? generation;

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    final status = _GenerationStatus.of(generation);

    if (summary == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: status ?? const Text('Todavía no hay resumen de hoy.'),
        ),
      );
    }

    final theme = Theme.of(context);
    final legend = summary.emojiLegend ?? const [];

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
      ),
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

class _StatusFilter extends ConsumerWidget {
  const _StatusFilter({required this.selected});

  final AudioStatus? selected;

  static const _options = [
    (null, 'Todos'),
    (AudioStatus.pending, 'Pendiente'),
    (AudioStatus.transcribed, 'Transcrito'),
    (AudioStatus.error, 'Error'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      children: [
        for (final (status, label) in _options)
          ChoiceChip(
            label: Text(label),
            selected: selected == status,
            onSelected: (_) =>
                ref.read(diaryFilterProvider.notifier).select(status),
          ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({super.key, required this.audio});

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
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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

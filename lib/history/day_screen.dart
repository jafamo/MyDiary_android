import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../diary/entry_widgets.dart';
import '../format.dart';
import '../models/audio.dart';
import '../models/history.dart';
import '../router.dart';
import 'history_provider.dart';

/// Un día del Historial: resumen y notas.
class DayScreen extends ConsumerStatefulWidget {
  const DayScreen({super.key, required this.date});

  final DateTime date;

  @override
  ConsumerState<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends ConsumerState<DayScreen> {
  /// Filtro por estado; `null` = todos. Cada día empieza sin filtro.
  AudioStatus? _filter;

  (DateTime, AudioStatus?) get _key => (widget.date, _filter);

  Future<void> _refresh() async {
    try {
      ref.invalidate(historyDayProvider(_key));
      await ref.read(historyDayProvider(_key).future);
    } on Object {
      // El error se muestra en la pantalla.
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(historyDayProvider(_key));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        bottom: day.isLoading && day.hasValue
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: switch (day) {
        AsyncValue(:final value?) => RefreshIndicator(
          onRefresh: _refresh,
          child: _DayView(
            day: value,
            filter: _filter,
            onFilter: (status) => setState(() => _filter = status),
            refreshError: day.hasError ? day.error : null,
          ),
        ),
        AsyncError(:final error) => LoadError(
          error: error,
          onRetry: () => ref.invalidate(historyDayProvider(_key)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _DayView extends StatelessWidget {
  const _DayView({
    required this.day,
    required this.filter,
    required this.onFilter,
    this.refreshError,
  });

  final HistoryDay day;
  final AudioStatus? filter;
  final ValueChanged<AudioStatus?> onFilter;
  final Object? refreshError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (refreshError != null) ...[
          RefreshErrorBanner(error: refreshError),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            _JumpButton(
              date: day.previousDate,
              tooltip: 'Día anterior con notas',
              icon: Icons.chevron_left,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    capitalize(formatDayWithYear(day.date)),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    plural(day.entries.length, 'audio', 'audios'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _JumpButton(
              date: day.nextDate,
              tooltip: 'Día siguiente con notas',
              icon: Icons.chevron_right,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SummaryCard(
          summary: day.summary,
          emptyText: 'Sin resumen de este día.',
        ),
        const SizedBox(height: 12),
        StatusFilter(selected: filter, onSelected: onFilter),
        const SizedBox(height: 8),
        if (day.entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              filter == null
                  ? 'Sin audios este día.'
                  : 'Ningún audio con este estado.',
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final entry in day.entries)
            EntryCard(key: ValueKey(entry.id), audio: entry),
      ],
    );
  }
}

/// Salta al día con actividad más cercano; desactivado si no hay.
class _JumpButton extends StatelessWidget {
  const _JumpButton({
    required this.date,
    required this.tooltip,
    required this.icon,
  });

  final DateTime? date;
  final String tooltip;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final date = this.date;

    return IconButton(
      onPressed: date == null
          ? null
          : () => context.go(Routes.historyDay(date)),
      tooltip: tooltip,
      icon: Icon(icon),
    );
  }
}

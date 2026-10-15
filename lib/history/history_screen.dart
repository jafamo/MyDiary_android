import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../diary/diary_provider.dart';
import '../diary/entry_widgets.dart';
import '../format.dart';
import '../models/history.dart';
import '../router.dart';
import 'history_provider.dart';

/// Historial: calendario de un mes con los días con notas.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  /// Mes que se ve; `null` = el actual según el backend.
  DateTime? _month;

  Future<void> _refresh() async {
    try {
      ref.invalidate(historyMonthProvider(_month));
      await ref.read(historyMonthProvider(_month).future);
    } on Object {
      // El error se muestra en la pantalla.
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyMonthProvider(_month));
    // Hoy lo decide el servidor; mientras el Diario no ha cargado, el dispositivo.
    final today =
        ref.watch(diaryProvider.select((d) => d.value?.date)) ??
        DateUtils.dateOnly(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: switch (history) {
        AsyncValue(:final value?) => RefreshIndicator(
          onRefresh: _refresh,
          child: _MonthView(
            history: value,
            today: today,
            onMonth: (month) => setState(() => _month = month),
          ),
        ),
        AsyncError(:final error) => LoadError(
          error: error,
          onRetry: () => ref.invalidate(historyMonthProvider(_month)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.history,
    required this.today,
    required this.onMonth,
  });

  static const _weekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  final HistoryMonth history;
  final DateTime today;
  final ValueChanged<DateTime> onMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final month = history.month;
    final hasNext = month.isBefore(DateTime(today.year, today.month));
    final active = {for (final day in history.days) day.date: day};
    // Huecos antes del día 1 (la semana empieza en lunes).
    final offset = month.weekday - 1;
    final cells = [
      for (var i = 0; i < offset; i++) null,
      for (
        var d = 1;
        d <= DateUtils.getDaysInMonth(month.year, month.month);
        d++
      )
        DateTime(month.year, month.month, d),
    ];

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 300) {
          onMonth(history.previousMonth);
        } else if (velocity < -300 && hasNext) {
          onMonth(history.nextMonth);
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => onMonth(history.previousMonth),
                tooltip: 'Mes anterior',
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  capitalize(formatMonth(month)),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: hasNext ? () => onMonth(history.nextMonth) : null,
                tooltip: 'Mes siguiente',
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final weekday in _weekdays)
                Expanded(
                  child: Text(
                    weekday,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var week = 0; week < cells.length; week += 7)
            Row(
              children: [
                for (var i = week; i < week + 7; i++)
                  Expanded(
                    child: i < cells.length && cells[i] != null
                        ? _DayCell(
                            date: cells[i]!,
                            activity: active[cells[i]],
                            isToday: cells[i] == today,
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.activity,
    required this.isToday,
  });

  final DateTime date;

  /// `null` si el día no tiene notas.
  final ActiveDay? activity;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final activity = this.activity;

    final cell = SizedBox(
      height: 64,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: isToday
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.primary, width: 1.5),
                  )
                : null,
            child: Text(
              '${date.day}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: activity == null ? colors.onSurfaceVariant : null,
                fontWeight: isToday ? FontWeight.bold : null,
              ),
            ),
          ),
          const SizedBox(height: 2),
          if (activity != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Puede haber resumen sin notas (borradas después): solo el punto.
                if (activity.audioCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${activity.audioCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (activity.hasSummary) ...[
                  if (activity.audioCount > 0) const SizedBox(width: 3),
                  Container(
                    key: const ValueKey('resumen'),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colors.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );

    if (activity == null) {
      return KeyedSubtree(key: ValueKey(date), child: cell);
    }
    return Semantics(
      key: ValueKey(date),
      button: true,
      label:
          '${formatDay(date)}, ${plural(activity.audioCount, 'nota', 'notas')}'
          '${activity.hasSummary ? ', con resumen' : ''}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go(Routes.historyDay(date)),
        child: cell,
      ),
    );
  }
}

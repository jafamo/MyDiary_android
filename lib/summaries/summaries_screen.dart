import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../diary/diary_provider.dart';
import '../diary/entry_widgets.dart';
import '../format.dart';
import '../models/summary.dart';
import '../router.dart';
import '../theme/ui_theme.dart';
import 'summaries_provider.dart';

/// Resúmenes de todos los días, del más reciente al más antiguo, con filtro por fechas.
class SummariesScreen extends ConsumerStatefulWidget {
  const SummariesScreen({super.key});

  @override
  ConsumerState<SummariesScreen> createState() => _SummariesScreenState();
}

class _SummariesScreenState extends ConsumerState<SummariesScreen> {
  DayRange? _range;

  Future<void> _refresh() async {
    try {
      ref.invalidate(summariesProvider(_range));
      await ref.read(summariesProvider(_range).future);
    } on Object {
      // El error se muestra en la pantalla.
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final today =
        ref.read(diaryProvider).value?.date ??
        DateTime(now.year, now.month, now.day);
    final range = _range;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      currentDate: today,
      initialDateRange: range == null
          ? null
          : DateTimeRange(start: range.$1, end: range.$2),
    );
    if (picked != null) {
      setState(() => _range = (picked.start, picked.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    final summaries = ref.watch(summariesProvider(range));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resúmenes'),
        actions: [
          IconButton(
            onPressed: _pickRange,
            tooltip: 'Filtrar por fechas',
            icon: const Icon(Icons.date_range),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (range != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: InputChip(
                avatar: const Icon(Icons.date_range, size: 18),
                label: Text(formatDayRange(range.$1, range.$2)),
                deleteButtonTooltipMessage: 'Quitar el filtro',
                onDeleted: () => setState(() => _range = null),
              ),
            ),
          Expanded(
            child: switch (summaries) {
              AsyncValue(:final value?) => RefreshIndicator(
                onRefresh: _refresh,
                child: _SummaryListView(
                  list: value,
                  emptyText: range == null
                      ? 'Todavía no hay resúmenes.'
                      : 'Sin resúmenes en estas fechas.',
                  onLoadMore: () =>
                      ref.read(summariesProvider(range).notifier).loadMore(),
                ),
              ),
              AsyncValue(:final error?) => LoadError(
                error: error,
                onRetry: () => ref.invalidate(summariesProvider(range)),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryListView extends StatelessWidget {
  const _SummaryListView({
    required this.list,
    required this.emptyText,
    required this.onLoadMore,
  });

  final SummaryList list;
  final String emptyText;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final items = list.items;
    if (items.isEmpty) {
      // Desplazable para que funcione deslizar hacia abajo.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [Center(child: Text(emptyText))],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1,
      itemBuilder: (context, index) => index < items.length
          ? Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SummaryTile(
                key: ValueKey(items[index].summary.id),
                item: items[index],
              ),
            )
          : _ListFooter(list: list, onLoadMore: onLoadMore),
    );
  }
}

/// Final de la lista: al construirse pide la página siguiente si quedan resúmenes.
class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.list, required this.onLoadMore});

  final SummaryList list;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final error = list.loadMoreError;
    if (error != null) {
      return Column(
        children: [
          Text(errorMessage(error), textAlign: TextAlign.center),
          TextButton(onPressed: onLoadMore, child: const Text('Reintentar')),
        ],
      );
    }
    if (!list.hasMore) return const SizedBox.shrink();

    if (!list.loadingMore) Future.microtask(onLoadMore);
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Resumen plegado (fecha, audios y tres líneas); al tocarlo se despliega entero.
class _SummaryTile extends StatefulWidget {
  const _SummaryTile({super.key, required this.item});

  final SummaryListItem item;

  @override
  State<_SummaryTile> createState() => _SummaryTileState();
}

class _SummaryTileState extends State<_SummaryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.item.summary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatShortDay(summary.date),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.mic_none, size: 16),
                    label: Text(
                      plural(widget.item.audioCount, 'audio', 'audios'),
                    ),
                    tooltip: 'Abrir el día',
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        context.go(Routes.historyDay(summary.date)),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  summary.summaryText,
                  maxLines: _expanded ? null : 3,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                ),
              ),
              if (_expanded) ...[
                SummaryExtras(summary: summary),
                const SizedBox(height: 12),
                _Metrics(summary: summary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Modelo, tokens y tiempo de generación; «—» si el resumen es anterior a su captura.
class _Metrics extends StatelessWidget {
  const _Metrics({required this.summary});

  final Summary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String or(int? value, String Function(int) format) =>
        value == null ? '—' : format(value);
    final prompt = summary.promptTokens;
    final completion = summary.completionTokens;
    final total = prompt != null && completion != null
        ? prompt + completion
        : null;

    return Text(
      '${summary.model ?? '—'} · ${or(total, formatNumber)} tokens '
      '(${or(prompt, formatNumber)} + ${or(completion, formatNumber)}) · '
      '${or(summary.generationMs, formatSeconds)}',
      style: theme.textTheme.bodySmall
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)
          .merge(DiaryStyle.of(context).figures),
    );
  }
}

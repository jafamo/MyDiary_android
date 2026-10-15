import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../format.dart';
import '../models/diary.dart';
import '../recording/recording_sheet.dart';
import '../screens/account_menu.dart';
import 'diary_provider.dart';
import 'entry_widgets.dart';

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

  Future<void> _record() async {
    final upload = await showRecordingSheet(context);
    if (upload == null || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(uploadMessage(upload.result))));
    ref.invalidate(diaryProvider);
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
      floatingActionButton: FloatingActionButton(
        onPressed: _record,
        tooltip: 'Grabar nota',
        child: const Icon(Icons.mic),
      ),
      body: switch (diary) {
        AsyncValue(:final value?) => RefreshIndicator(
          onRefresh: _refresh,
          child: _DiaryView(
            diary: value,
            refreshError: diary.hasError ? diary.error : null,
          ),
        ),
        AsyncError(:final error) => LoadError(
          error: error,
          onRetry: () => ref.invalidate(diaryProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
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
      // Abajo, sitio para el botón de grabar.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        if (refreshError != null) ...[
          RefreshErrorBanner(error: refreshError),
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
        SummaryCard(
          summary: diary.summary,
          generation: diary.summaryGeneration,
          emptyText: 'Todavía no hay resumen de hoy.',
        ),
        const SizedBox(height: 12),
        StatusFilter(
          selected: filter,
          onSelected: ref.read(diaryFilterProvider.notifier).select,
        ),
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
            EntryCard(key: ValueKey(entry.id), audio: entry),
      ],
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

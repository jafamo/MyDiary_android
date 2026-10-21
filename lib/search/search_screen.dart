import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../diary/entry_widgets.dart';
import '../format.dart';
import '../models/reminder.dart';
import '../models/search.dart';
import '../models/summary.dart';
import '../router.dart';
import 'search_provider.dart';

/// Búsqueda semántica en notas y resúmenes, y por texto en recordatorios. Se busca al enviar,
/// no mientras se escribe: cada consulta pide los embeddings a la IA del servidor.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  /// Última consulta enviada; `null` = todavía no se ha buscado.
  String? _query;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String text) {
    final query = text.trim();
    if (query.isEmpty) return;
    if (query == _query) {
      ref.invalidate(searchProvider(query));
    } else {
      setState(() => _query = query);
    }
  }

  void _clear() {
    _controller.clear();
    setState(() => _query = null);
  }

  @override
  Widget build(BuildContext context) {
    final query = _query;

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: _submit,
                decoration: InputDecoration(
                  hintText: '¿Cuándo hablé de...?',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _clear,
                          tooltip: 'Borrar',
                          icon: const Icon(Icons.close),
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ),
          Expanded(
            child: query == null
                ? const _Message(
                    'Escribe lo que buscas con tus palabras: se busca en las '
                    'notas, los resúmenes y los recordatorios.',
                  )
                : switch (ref.watch(searchProvider(query))) {
                    // También al repetir la búsqueda o al reintentar tras un error.
                    AsyncValue(isLoading: true) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    AsyncValue(:final value?) =>
                      value.isEmpty
                          ? _Message('Sin resultados para «$query».')
                          : _ResultsView(results: value),
                    AsyncError(:final error) => LoadError(
                      error: error,
                      onRetry: () => ref.invalidate(searchProvider(query)),
                    ),
                    _ => const SizedBox.shrink(),
                  },
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.results});

  final SearchResults results;

  @override
  Widget build(BuildContext context) {
    void openDay(DateTime date) => context.go(Routes.historyDay(date));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (results.reminders.isNotEmpty) ...[
          _SectionTitle(
            icon: Icons.notifications_none,
            title: 'Recordatorios',
            count: results.reminders.length,
          ),
          for (final reminder in results.reminders)
            _ReminderCard(key: ValueKey(reminder.id), reminder: reminder),
          const SizedBox(height: 16),
        ],
        if (results.results.isNotEmpty) ...[
          _SectionTitle(
            icon: Icons.mic_none,
            title: 'Notas y resúmenes',
            count: results.results.length,
          ),
          for (final result in results.results)
            switch (result) {
              NoteResult(:final audio, :final date) => EntryCard(
                key: ValueKey('nota ${audio.id}'),
                audio: audio,
                date: date,
                onOpenDay: () => openDay(date),
              ),
              SummaryResult(:final summary) => _SummaryResultCard(
                key: ValueKey('resumen ${summary.id}'),
                summary: summary,
                onOpenDay: () => openDay(summary.date),
              ),
            },
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({super.key, required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final time = reminder.time;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.event),
        title: Text(reminder.text),
        subtitle: Text(
          '${formatShortDay(reminder.date)}${time == null ? '' : ' · $time'}',
        ),
      ),
    );
  }
}

/// Resumen encontrado: plegado a 4 líneas; desplegado, con la leyenda y los temas.
class _SummaryResultCard extends StatelessWidget {
  const _SummaryResultCard({
    super.key,
    required this.summary,
    required this.onOpenDay,
  });

  final Summary summary;
  final VoidCallback onOpenDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${formatShortDay(summary.date)} · Resumen del día',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExpandableText(
              summary.summaryText,
              details: SummaryExtras(summary: summary),
              action: OpenDayButton(onOpenDay),
            ),
          ],
        ),
      ),
    );
  }
}

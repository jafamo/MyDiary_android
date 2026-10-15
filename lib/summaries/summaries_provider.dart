import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/json.dart';
import '../history/history_provider.dart';
import '../models/paginated.dart';
import '../models/summary.dart';
import '../providers.dart';

/// Rango de días (los dos inclusive) por el que se filtran los resúmenes.
typedef DayRange = (DateTime from, DateTime to);

/// Resúmenes cargados hasta ahora y el estado de la página siguiente.
class SummaryList {
  const SummaryList({
    required this.items,
    required this.total,
    required this.page,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<SummaryListItem> items;
  final int total;

  /// Última página cargada.
  final int page;
  final bool loadingMore;

  /// Error de la última petición de la página siguiente.
  final Object? loadMoreError;

  bool get hasMore => items.length < total;
}

/// Lista paginada de resúmenes, del más reciente al más antiguo; `null` = sin filtro.
final summariesProvider = AsyncNotifierProvider.autoDispose
    .family<SummariesNotifier, SummaryList, DayRange?>(
      SummariesNotifier.new,
      retry: (_, _) => null,
    );

class SummariesNotifier extends AsyncNotifier<SummaryList> {
  SummariesNotifier(this.range);

  final DayRange? range;

  @override
  Future<SummaryList> build() async {
    final page = await _fetch(1);
    return SummaryList(items: page.items, total: page.total, page: 1);
  }

  /// Pide la página siguiente si quedan resúmenes y no hay otra petición en curso.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(_copy(current, loadingMore: true));

    try {
      final page = await _fetch(current.page + 1);
      // Si entre páginas llega un resumen nuevo, el corte se desplaza y se repetiría uno.
      final known = {for (final item in current.items) item.summary.id};
      state = AsyncData(
        SummaryList(
          items: [
            ...current.items,
            for (final item in page.items)
              if (!known.contains(item.summary.id)) item,
          ],
          total: page.total,
          page: current.page + 1,
        ),
      );
    } on Object catch (error) {
      state = AsyncData(_copy(current, loadMoreError: error));
    }
  }

  Future<Paginated<SummaryListItem>> _fetch(int page) {
    final range = this.range;

    return ref
        .read(apiClientProvider)
        .get(
          '/resumenes',
          query: {
            if (range != null) ...{
              'from': formatDayParam(range.$1),
              'to': formatDayParam(range.$2),
            },
            'page': page,
          },
          parse: (json) =>
              Paginated.fromJson(asJson(json), SummaryListItem.fromJson),
        );
  }

  static SummaryList _copy(
    SummaryList list, {
    bool loadingMore = false,
    Object? loadMoreError,
  }) => SummaryList(
    items: list.items,
    total: list.total,
    page: list.page,
    loadingMore: loadingMore,
    loadMoreError: loadMoreError,
  );
}

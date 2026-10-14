import '../api/json.dart';

/// Listado paginado de la API: `{items, page, per_page, total}`.
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
  });

  factory Paginated.fromJson(Json json, T Function(Json json) item) =>
      Paginated(
        items: json.list('items', item),
        page: json.integer('page'),
        perPage: json.integer('per_page'),
        total: json.integer('total'),
      );

  final List<T> items;
  final int page;
  final int perPage;
  final int total;

  bool get hasMore => page * perPage < total;
}

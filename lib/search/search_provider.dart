import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/json.dart';
import '../models/search.dart';
import '../providers.dart';

/// Resultados de una consulta ya recortada y no vacía.
final searchProvider = FutureProvider.autoDispose.family<SearchResults, String>(
  (ref, query) {
    return ref
        .watch(apiClientProvider)
        .get(
          '/busqueda',
          query: {'q': query},
          parse: (json) => SearchResults.fromJson(asJson(json)),
        );
  },
  retry: (_, _) => null,
);

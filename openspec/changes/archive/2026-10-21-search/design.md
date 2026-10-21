## Context

`GET /api/v1/busqueda?q=` devuelve `{query, results, reminders}`. Cada resultado es `{type, distance, date, audio, summary}`: `audio` va si `type` es `transcription` y `summary` si es `daily_summary`. Como mucho 20, ya ordenados por `distance`. Sin `q` o con `q` vacío responde `422`. Si el servicio de embeddings falla, `results` va vacío sin avisar y los recordatorios salen igual.

## Decisions

- **Provider por consulta**: `FutureProvider.autoDispose.family<SearchResults, String>`. La pantalla guarda la consulta enviada (recortada; vacía no busca) y observa su provider. Como la pestaña sigue montada en el `StatefulShellRoute`, los resultados se conservan al cambiar de sección. Repetir la misma consulta vuelve a pedirla (`invalidate`).
- **Tipo de resultado desconocido**: se descarta al parsear (un `type` futuro no rompe la lista). Si falta el `audio` o el `summary` que corresponde a su tipo, el JSON es inválido.
- **Reutilizar la tarjeta de nota del Diario**: `EntryCard` acepta un `showDate` y una acción `onOpenDay` en lugar de duplicarla. El texto plegable con «Ver más» pasa a ser público para usarlo también en los resúmenes.
- **Recordatorios sin enlace**: su pantalla es otra parte de la fase 5; cuando exista, se enlazará desde aquí.
- **No se muestra la `distance`**: el orden ya la refleja y el número no le dice nada al usuario.

## Risks / Trade-offs

- Si fallan los embeddings, la app dice «Sin resultados» aunque haya coincidencias: la API no lo distingue. Se acepta, igual que en la web.

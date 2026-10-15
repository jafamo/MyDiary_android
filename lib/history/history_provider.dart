import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../api/json.dart';
import '../diary/diary_provider.dart';
import '../models/audio.dart';
import '../models/history.dart';
import '../providers.dart';

/// Calendario de un mes (su día 1); `null` = el mes actual según el backend.
final historyMonthProvider = FutureProvider.autoDispose
    .family<HistoryMonth, DateTime?>((ref, month) {
      return ref
          .watch(apiClientProvider)
          .get(
            '/historial',
            query: {if (month != null) 'month': formatMonthParam(month)},
            parse: (json) => HistoryMonth.fromJson(asJson(json)),
          );
    }, retry: (_, _) => null);

/// Audios y resumen de un día, con el filtro por estado (`null` = todos).
final historyDayProvider = FutureProvider.autoDispose
    .family<HistoryDay, (DateTime, AudioStatus?)>((ref, key) {
      final (date, status) = key;

      return ref
          .watch(apiClientProvider)
          .get(
            '/historial/${formatDayParam(date)}',
            query: {if (status != null) 'status': statusParam(status)},
            parse: (json) => HistoryDay.fromJson(asJson(json)),
          );
    }, retry: (_, _) => null);

/// `AAAA-MM`.
String formatMonthParam(DateTime month) => DateFormat('yyyy-MM').format(month);

/// `AAAA-MM-DD`.
String formatDayParam(DateTime day) => DateFormat('yyyy-MM-dd').format(day);

final _dayParam = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Fecha de la ruta del día (`AAAA-MM-DD`), o `null` si no es un día válido.
DateTime? parseDayParam(String value) {
  final parsed = _dayParam.hasMatch(value) ? DateTime.tryParse(value) : null;
  return parsed != null && formatDayParam(parsed) == value ? parsed : null;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/json.dart';
import '../models/audio.dart';
import '../models/diary.dart';
import '../providers.dart';

/// Filtro por estado de la portada; `null` = todos.
final diaryFilterProvider = NotifierProvider<DiaryFilter, AudioStatus?>(
  DiaryFilter.new,
);

class DiaryFilter extends Notifier<AudioStatus?> {
  @override
  AudioStatus? build() => null;

  void select(AudioStatus? status) => state = status;
}

/// Portada de hoy. Sin reintento automático: el error se muestra y se reintenta a mano
/// o con el siguiente sondeo. `autoDispose` para descartarla al cerrar sesión.
final diaryProvider = FutureProvider.autoDispose<Diary>((ref) {
  final status = ref.watch(diaryFilterProvider);

  return ref
      .watch(apiClientProvider)
      .get(
        '/diario',
        query: {if (status != null) 'status': _statusParam(status)},
        parse: (json) => Diary.fromJson(asJson(json)),
      );
}, retry: (_, _) => null);

String _statusParam(AudioStatus status) => switch (status) {
  AudioStatus.pending => 'PENDING',
  AudioStatus.transcribed => 'TRANSCRIBED',
  AudioStatus.error => 'ERROR',
  AudioStatus.unknown => throw ArgumentError.value(status, 'status'),
};

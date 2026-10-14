import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary/api/api_exception.dart';
import 'package:mydiary/auth/session_notifier.dart';
import 'package:mydiary/diary/diary_provider.dart';
import 'package:mydiary/models/audio.dart';

import '../support/app_harness.dart';
import '../support/fake_http.dart';

void main() {
  late FakeAdapter backend;
  late ProviderContainer container;

  setUp(() {
    backend = fakeBackend();
    container = createTestContainer(
      backend: backend,
      storage: MemoryTokenStorage(storedSession),
    );
  });

  /// Mantiene vivo el provider `autoDispose` mientras dura el test.
  Future<void> listenDiary() async {
    await container.read(sessionProvider.future);
    container.listen(diaryProvider, (_, _) {});
  }

  test('sin filtro pide el diario sin status', () async {
    await listenDiary();

    final diary = await container.read(diaryProvider.future);

    expect(diary.entries, hasLength(3));
    expect(backend.requests.last.uri.path, '/api/v1/diario');
    expect(backend.requests.last.uri.queryParameters, isEmpty);
  });

  test('con filtro pide el status de la API', () async {
    await listenDiary();
    await container.read(diaryProvider.future);

    container.read(diaryFilterProvider.notifier).select(AudioStatus.error);
    await container.read(diaryProvider.future);

    expect(backend.requests.last.uri.queryParameters, {'status': 'ERROR'});
  });

  test('un error no se reintenta solo', () async {
    await listenDiary();
    backend.handler = networkDown;

    await expectLater(
      container.read(diaryProvider.future),
      throwsA(isA<ApiException>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));

    expect(backend.calls.where((c) => c == 'GET /api/v1/diario'), hasLength(1));
  });
}

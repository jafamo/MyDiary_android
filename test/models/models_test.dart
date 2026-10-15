import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary/api/json.dart';
import 'package:mydiary/models/audio.dart';
import 'package:mydiary/models/audio_upload.dart';
import 'package:mydiary/models/diary.dart';
import 'package:mydiary/models/paginated.dart';
import 'package:mydiary/models/reminder.dart';
import 'package:mydiary/models/summary.dart';
import 'package:mydiary/models/summary_generation.dart';

import '../fixtures.dart';

void main() {
  group('Audio', () {
    test('audio transcrito con su transcripción', () {
      final audio = Audio.fromJson(fixture('audio_transcribed'));

      expect(audio.id, 42);
      expect(audio.status, AudioStatus.transcribed);
      expect(audio.source, AudioSource.app);
      expect(audio.durationSeconds, 37);
      expect(audio.receivedAt, DateTime.utc(2026, 10, 8, 7, 9, 33));
      expect(audio.receivedAt.isUtc, isTrue);
      expect(audio.errorCode, isNull);
      expect(
        audio.transcription!.content,
        startsWith('Hoy he ido al dentista'),
      );
      expect(audio.transcription!.editedManually, isFalse);
      expect(audio.transcription!.processingMs, 14200);
    });

    test('audio con error y sin transcripción', () {
      final audio = Audio.fromJson(fixture('audio_error'));

      expect(audio.status, AudioStatus.error);
      expect(audio.source, AudioSource.telegram);
      expect(audio.errorCode, 'TIMEOUT');
      expect(audio.errorMessage, 'OLLAMA_UNREACHABLE');
      expect(audio.transcription, isNull);
    });

    test('forma breve (subida) sin error ni transcripción', () {
      final json = fixture('audio_transcribed')
        ..remove('error_code')
        ..remove('error_message')
        ..remove('transcription');

      expect(Audio.fromJson(json).transcription, isNull);
    });

    test('estado desconocido no falla', () {
      final json = fixture('audio_transcribed')..['status'] = 'ARCHIVED';

      expect(Audio.fromJson(json).status, AudioStatus.unknown);
    });

    test('campo obligatorio ausente lanza FormatException', () {
      final json = fixture('audio_transcribed')..remove('received_at');

      expect(() => Audio.fromJson(json), throwsFormatException);
    });

    test('instante sin zona UTC se rechaza', () {
      final json = fixture('audio_transcribed')
        ..['received_at'] = '2026-10-08T07:09:33';

      expect(() => Audio.fromJson(json), throwsFormatException);
    });
  });

  group('Summary', () {
    test('resumen con temas, leyenda y métricas', () {
      final summary = Summary.fromJson(fixture('summary'));

      expect(summary.date, DateTime(2026, 10, 5));
      expect(summary.date.isUtc, isFalse);
      expect(summary.topics.map((t) => t.name), ['trabajo', 'salud']);
      expect(summary.emojiLegend!.first.meaning, 'Trabajo');
      expect(summary.promptTokens, 2980);
    });

    test('resumen antiguo sin leyenda ni métricas', () {
      final json = fixture('summary')
        ..['emoji_legend'] = null
        ..['model'] = null
        ..['prompt_tokens'] = null
        ..['completion_tokens'] = null
        ..['generation_ms'] = null;

      final summary = Summary.fromJson(json);

      expect(summary.emojiLegend, isNull);
      expect(summary.model, isNull);
      expect(summary.generationMs, isNull);
    });

    test('día imposible se rechaza', () {
      final json = fixture('summary')..['date'] = '2026-02-30';

      expect(() => Summary.fromJson(json), throwsFormatException);
    });
  });

  test('SummaryGeneration atascada', () {
    final generation = SummaryGeneration.fromJson(
      fixture('summary_generation_stalled'),
    );

    expect(generation.status, SummaryGenerationStatus.failed);
    expect(generation.status.inProgress, isFalse);
    expect(generation.errorCode, 'STALLED');
    expect(generation.startedAt, isNull);
  });

  test('página de recordatorios, con y sin hora', () {
    final page = Paginated.fromJson(
      fixture('reminders_page'),
      Reminder.fromJson,
    );

    expect(page.total, 2);
    expect(page.perPage, 20);
    expect(page.hasMore, isFalse);
    expect(page.items.first.date, DateTime(2026, 10, 20));
    expect(page.items.first.time, '10:30');
    expect(page.items.last.time, isNull);
    expect(page.items.last.updatedAt, DateTime.utc(2026, 10, 9, 8));
  });

  group('Diary', () {
    test('portada completa', () {
      final diary = Diary.fromJson(fixture('diary'));

      expect(diary.date, DateTime(2026, 10, 14));
      expect(diary.entries.map((e) => e.status), [
        AudioStatus.transcribed,
        AudioStatus.pending,
        AudioStatus.error,
      ]);
      expect(diary.summary!.topics.map((t) => t.name), ['trabajo', 'salud']);
      expect(diary.summaryGeneration, isNull);
      expect(diary.streak.current, 4);
      expect(diary.streak.best, 12);
      expect(diary.week.total, 9);
      expect(diary.week.delta, 2);
      expect(diary.topTopic!.name, 'trabajo');
      expect(diary.topTopic!.count, 6);
    });

    test('sin resumen ni tema del mes', () {
      final diary = Diary.fromJson({
        ...fixture('diary'),
        'entries': <Object?>[],
        'summary': null,
        'top_topic': null,
      });

      expect(diary.entries, isEmpty);
      expect(diary.summary, isNull);
      expect(diary.topTopic, isNull);
    });

    group('needsPolling', () {
      Json withEntries(List<String> statuses, {String? generation}) => {
        ...fixture('diary'),
        'entries': [
          for (final (i, status) in statuses.indexed)
            {
              ...fixture('audio_transcribed'),
              'id': i,
              'status': status,
              'transcription': null,
            },
        ],
        'summary_generation': generation == null
            ? null
            : {...fixture('summary_generation_stalled'), 'status': generation},
      };

      test('con un audio pendiente', () {
        expect(
          Diary.fromJson(withEntries(['TRANSCRIBED', 'PENDING'])).needsPolling,
          isTrue,
        );
      });

      test('con el resumen en curso', () {
        expect(
          Diary.fromJson(withEntries(['TRANSCRIBED'], generation: 'QUEUED'))
              .needsPolling,
          isTrue,
        );
      });

      test('sin nada en curso', () {
        expect(
          Diary.fromJson(
            withEntries(['TRANSCRIBED', 'ERROR'], generation: 'FAILED'),
          ).needsPolling,
          isFalse,
        );
      });
    });
  });

  group('AudioUpload', () {
    test('audio breve con el resultado', () {
      final upload = AudioUpload.fromJson(fixture('audio_upload'));

      expect(upload.result, UploadResult.created);
      expect(upload.audio.id, 45);
      expect(upload.audio.status, AudioStatus.pending);
      expect(upload.audio.source, AudioSource.app);
      expect(upload.audio.transcription, isNull);
    });

    test('resultados conocidos y desconocidos', () {
      expect(UploadResult.fromJson('duplicate'), UploadResult.duplicate);
      expect(UploadResult.fromJson('retrying'), UploadResult.retrying);
      expect(UploadResult.fromJson('otro'), UploadResult.unknown);
    });
  });
}

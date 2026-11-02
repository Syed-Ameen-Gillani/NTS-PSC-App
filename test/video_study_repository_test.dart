import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/learn/data/video_study_repository.dart';
import 'package:nts_psc_app/features/learn/domain/video_study_state.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_study_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/video_study_panel.dart';

void main() {
  late Directory directory;
  late VideoStudyRepository repository;
  const key = (userId: 'student-a', lessonId: 'lesson', source: 'media-v1');
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('video-study-test');
    repository = VideoStudyRepository(() async => directory);
  });
  tearDown(() async => directory.delete(recursive: true));

  test(
    'position, settings and personal notes persist across repository instances',
    () async {
      const saved = VideoStudyState(
        positionMs: 34000,
        speed: 1.5,
        captions: true,
        volume: 0.4,
        notes: [
          VideoStudyNote(id: 'note', seconds: 12, text: 'My actual note'),
        ],
      );
      await repository.write(key, saved);
      final restored = await VideoStudyRepository(
        () async => directory,
      ).read(key);
      expect(restored.positionMs, 34000);
      expect(restored.speed, 1.5);
      expect(restored.captions, true);
      expect(restored.volume, 0.4);
      expect(restored.notes.single.text, 'My actual note');
    },
  );

  test('accounts, lessons and replaced media do not share state', () async {
    await repository.write(key, const VideoStudyState(positionMs: 20000));
    for (final other in [
      (userId: 'student-b', lessonId: 'lesson', source: 'media-v1'),
      (userId: 'student-a', lessonId: 'other', source: 'media-v1'),
      (userId: 'student-a', lessonId: 'lesson', source: 'media-v2'),
    ]) {
      expect((await repository.read(other)).positionMs, 0);
    }
  });

  test('rapid pause/dispose writes preserve newer notes', () async {
    const stale = VideoStudyState(positionMs: 10000);
    const note = VideoStudyNote(id: 'note', seconds: 10, text: 'Keep me');
    final first = repository.write(key, stale.copyWith(notes: [note]));
    final second = repository.writePlayback(
      key,
      stale.copyWith(positionMs: 18000),
    );
    final third = repository.writePlayback(
      key,
      stale.copyWith(positionMs: 23000),
    );
    await first;
    await second;
    await third;
    final saved = await repository.read(key);
    expect(saved.positionMs, 23000);
    expect(saved.notes.single.id, 'note');
  });

  test('resume bounds, completed video and malformed settings are safe', () {
    expect(
      const VideoStudyState(
        positionMs: 60000,
      ).resumePosition(const Duration(seconds: 60)),
      Duration.zero,
    );
    expect(
      const VideoStudyState(
        positionMs: 59000,
      ).resumePosition(const Duration(seconds: 60)),
      Duration.zero,
    );
    expect(
      const VideoStudyState(
        positionMs: 20000,
      ).resumePosition(const Duration(seconds: 60)),
      const Duration(seconds: 20),
    );
    final parsed = VideoStudyState.fromJson({
      'positionMs': -1,
      'speed': double.nan,
      'notes': [
        {'id': 'x', 'seconds': -1, 'text': 'Invalid'},
      ],
    });
    expect(parsed.positionMs, 0);
    expect(parsed.speed, 1);
    expect(VideoStudyState.fromJson({'volume': double.nan}).volume, 1);
    expect(VideoStudyState.fromJson({'volume': -1}).volume, 1);
    expect(VideoStudyState.fromJson({'volume': 0}).volume, 0);
    expect(parsed.notes, isEmpty);
  });

  test('corrupt metadata recovers on a valid playback save', () async {
    await repository.write(key, const VideoStudyState());
    final file = (await directory.list().toList()).whereType<File>().single;
    await file.writeAsString('{incomplete');
    expect((await repository.read(key)).positionMs, 0);
    await repository.writePlayback(
      key,
      const VideoStudyState(positionMs: 12000),
    );
    expect((await repository.read(key)).positionMs, 12000);
  });

  test(
    'notes can be added, edited and deleted without losing playback',
    () async {
      final container = ProviderContainer(
        overrides: [videoStudyRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(videoStudyProvider(key), (_, _) {});
      addTearDown(subscription.close);
      final controller = container.read(videoStudyProvider(key).notifier);
      while (container.read(videoStudyProvider(key)).isLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      await controller.savePlayback(15000, 1.25, true);
      await controller.saveNote(seconds: 15, text: 'First note');
      final id = container
          .read(videoStudyProvider(key))
          .requireValue
          .notes
          .single
          .id;
      await controller.saveNote(id: id, seconds: 15, text: 'Edited note');
      expect(
        container.read(videoStudyProvider(key)).requireValue.notes.single.text,
        'Edited note',
      );
      expect((await repository.read(key)).positionMs, 15000);
      await controller.removeNote(id);
      expect((await repository.read(key)).notes, isEmpty);
    },
  );

  test(
    'transcript search supports real Unicode text and ignores invalid segments',
    () {
      final values = [
        {'start': 0, 'end': 5, 'text': 'Kashmir history'},
        {'start': 5, 'end': 10, 'text': '\u062a\u0627\u0631\u06cc\u062e'},
        {'start': 'invalid', 'end': 10, 'text': 'Bad'},
        {'start': 10, 'end': 1, 'text': 'Bad'},
      ];
      expect(searchableTranscript(values, 'HISTORY').single.start, 0);
      expect(
        searchableTranscript(
          values,
          '\u062a\u0627\u0631\u06cc\u062e',
        ).single.start,
        5,
      );
      expect(searchableTranscript(values, ''), hasLength(2));
    },
  );
}

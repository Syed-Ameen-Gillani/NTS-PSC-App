import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/learn/data/video_study_repository.dart';
import 'package:nts_psc_app/features/learn/data/learning_evidence_repository.dart';
import 'package:nts_psc_app/features/learn/domain/video_study_state.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/study_video_player.dart';

import 'support/fake_video_controller.dart';
import 'support/memory_video_study_repository.dart';
import 'support/fake_learning_evidence_repository.dart';

class _LearningSession extends FakeLearningEvidenceRepository {
  final ready = Completer<Map<String, dynamic>?>();

  @override
  Future<Map<String, dynamic>?> videoSession(String lesson, {String? source}) =>
      ready.future;
}

class _CountingPlaybackRepository extends MemoryVideoStudyRepository {
  int playbackWrites = 0;

  @override
  Future<void> writePlayback(VideoStudyKey key, VideoStudyState state) async {
    playbackWrites++;
    await super.writePlayback(key, state);
  }
}

class _ReadyLearningSession extends FakeLearningEvidenceRepository {
  _ReadyLearningSession({this.units = 120000});
  final int units;

  @override
  Future<Map<String, dynamic>?> videoSession(
    String lesson, {
    String? source,
  }) async => {'id': 'session', 'units': units};
}

class _SignedIn extends AuthController {
  @override
  AuthState build() => AuthState(
    isAuthenticated: true,
    user: UserModel(
      id: 'student',
      name: 'Student',
      email: 'test@example.invalid',
      imagePath: '',
      isPremium: false,
      courses: 0,
      quizzes: 0,
      avgScore: 0,
    ),
  );
}

Widget _app(
  MemoryVideoStudyRepository repository,
  Widget child, {
  LearningEvidenceRepository? evidence,
}) => ProviderScope(
  overrides: [
    videoStudyRepositoryProvider.overrideWithValue(repository),
    authControllerProvider.overrideWith(_SignedIn.new),
    if (evidence != null)
      learningEvidenceRepositoryProvider.overrideWithValue(evidence),
  ],
  child: ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, _) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  ),
);

void main() {
  const scope = (userId: 'student', lessonId: 'lesson', source: 'video-v1');
  testWidgets('buffering flaps do not save as pauses; real pause still saves', (
    tester,
  ) async {
    final repository = _CountingPlaybackRepository();
    final video = FakeVideoController();
    addTearDown(video.dispose);
    await tester.pumpWidget(
      _app(
        repository,
        StudyVideoPlayer(
          controller: video,
          lessonId: 'lesson',
          source: 'video-v1',
          title: 'Lesson',
          autoPlay: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final baseline = repository.playbackWrites;
    for (var i = 0; i < 8; i++) {
      video.value = video.value.copyWith(isPlaying: false, isBuffering: true);
      await tester.pump(const Duration(milliseconds: 50));
      video.value = video.value.copyWith(isPlaying: true, isBuffering: false);
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(repository.playbackWrites, baseline);
    await video.pause();
    await tester.pumpAndSettle();
    expect(repository.playbackWrites, baseline + 1);
  });
  testWidgets(
    'retry restores exact playback settings rather than stale disk state',
    (tester) async {
      final repository = MemoryVideoStudyRepository();
      repository.values[scope] = const VideoStudyState(positionMs: 10000);
      final video = FakeVideoController();
      addTearDown(video.dispose);
      await tester.pumpWidget(
        _app(
          repository,
          StudyVideoPlayer(
            controller: video,
            lessonId: 'lesson',
            source: 'video-v1',
            title: 'Lesson',
            autoPlay: true,
            recoveryState: const VideoStudyState(
              positionMs: 43000,
              speed: 1.75,
              volume: 0.3,
              captions: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(video.value.position, const Duration(seconds: 43));
      expect(video.value.playbackSpeed, 1.75);
      expect(video.value.volume, 0.3);
      expect(video.value.isPlaying, true);
    },
  );
  testWidgets('autoplay waits until progress tracking is ready', (
    tester,
  ) async {
    final repository = MemoryVideoStudyRepository();
    final evidence = _LearningSession();
    final video = FakeVideoController();
    addTearDown(video.dispose);
    await tester.pumpWidget(
      _app(
        repository,
        StudyVideoPlayer(
          controller: video,
          lessonId: 'lesson',
          source: 'video-v1',
          title: 'Lesson',
          trackLearning: true,
          autoPlay: true,
        ),
        evidence: evidence,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(video.value.isPlaying, isFalse);
    evidence.ready.complete(null);
    await tester.pumpAndSettle();
    expect(video.value.isPlaying, isFalse);
    expect(find.textContaining('Progress is unavailable'), findsOneWidget);
  });
  testWidgets('autoplay starts after a learning session is available', (
    tester,
  ) async {
    final video = FakeVideoController();
    addTearDown(video.dispose);
    await tester.pumpWidget(
      _app(
        MemoryVideoStudyRepository(),
        StudyVideoPlayer(
          controller: video,
          lessonId: 'lesson',
          source: 'video-v1',
          title: 'Lesson',
          trackLearning: true,
          autoPlay: true,
        ),
        evidence: _ReadyLearningSession(),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(video.value.isPlaying, isTrue);
  });
  testWidgets('impossible confirmed duration prevents untracked playback', (
    tester,
  ) async {
    final video = FakeVideoController();
    addTearDown(video.dispose);
    await tester.pumpWidget(
      _app(
        MemoryVideoStudyRepository(),
        StudyVideoPlayer(
          controller: video,
          lessonId: 'lesson',
          source: 'video-v1',
          title: 'Lesson',
          trackLearning: true,
          autoPlay: true,
        ),
        evidence: _ReadyLearningSession(units: 200000),
      ),
    );
    await tester.pumpAndSettle();
    expect(video.value.isPlaying, isFalse);
    expect(find.textContaining('duration checked'), findsOneWidget);
  });
  testWidgets('reopening restores position, speed and caption preference', (
    tester,
  ) async {
    final repository = MemoryVideoStudyRepository();
    repository.values[scope] = const VideoStudyState(
      positionMs: 25000,
      speed: 1.5,
      captions: true,
      volume: 0.4,
    );
    final video = FakeVideoController();
    addTearDown(video.dispose);
    await tester.pumpWidget(
      _app(
        repository,
        StudyVideoPlayer(
          showStudyPanel: true,
          controller: video,
          lessonId: 'lesson',
          source: 'video-v1',
          title: 'Lesson',
          segments: const [
            {'start': 0, 'end': 60, 'text': 'Real caption'},
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(video.value.position, const Duration(seconds: 25));
    expect(video.value.playbackSpeed, 1.5);
    expect(video.value.volume, 0.4);
    expect(video.value.isPlaying, false);
    expect(find.text('Real caption'), findsOneWidget);
    await video.seekTo(const Duration(seconds: 43));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(repository.values[scope]!.positionMs, 43000);
    expect(repository.values[scope]!.volume, 0.4);
    expect(video.disposed, false);
  });

  testWidgets('transcript search and timestamped notes work without dialogs', (
    tester,
  ) async {
    final repository = MemoryVideoStudyRepository();
    final video = FakeVideoController();
    addTearDown(video.dispose);
    await tester.pumpWidget(
      _app(
        repository,
        StudyVideoPlayer(
          showStudyPanel: true,
          controller: video,
          lessonId: 'lesson',
          source: 'video-v1',
          title: 'Lesson',
          segments: const [
            {'start': 0, 'end': 10, 'text': 'First concept'},
            {'start': 20, 'end': 30, 'text': 'Regional history'},
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transcript'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'history');
    await tester.pumpAndSettle();
    expect(find.text('First concept'), findsNothing);
    await tester.tap(find.text('Regional history'));
    await tester.pump();
    expect(video.value.position, const Duration(seconds: 20));
    await tester.tap(find.text('Transcript'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('My notes'));
    await tester.tap(find.text('My notes'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add note'));
    await tester.tap(find.text('Add note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Remember this topic');
    await tester.ensureVisible(find.byTooltip('Save note'));
    await tester.tap(find.byTooltip('Save note'));
    await tester.pumpAndSettle();
    expect(repository.values[scope]!.notes.single.text, 'Remember this topic');
    expect(repository.values[scope]!.notes.single.seconds, 20);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('deleted timestamped note can be restored with Undo', (
    tester,
  ) async {
    final repository = MemoryVideoStudyRepository();
    repository.values[scope] = const VideoStudyState(
      notes: [
        VideoStudyNote(id: 'saved-note', seconds: 35, text: 'Keep this note'),
      ],
    );
    final video = FakeVideoController();
    addTearDown(video.dispose);
    await tester.pumpWidget(
      _app(
        repository,
        StudyVideoPlayer(
          showStudyPanel: true,
          controller: video,
          lessonId: 'lesson',
          source: 'video-v1',
          title: 'Lesson',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('My notes'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Note options'));
    await tester.tap(find.byTooltip('Note options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(repository.values[scope]!.notes, isEmpty);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(repository.values[scope]!.notes.single.id, 'saved-note');
    expect(repository.values[scope]!.notes.single.seconds, 35);
    expect(find.text('Keep this note'), findsOneWidget);
  });

  testWidgets('opt-in autoplay starts playback and emits completion once', (
    tester,
  ) async {
    final repository = MemoryVideoStudyRepository();
    final video = FakeVideoController();
    addTearDown(video.dispose);
    var ended = 0;
    await tester.pumpWidget(
      _app(
        repository,
        StudyVideoPlayer(
          showStudyPanel: true,
          controller: video,
          lessonId: 'lesson',
          source: 'video-v1',
          title: 'Lesson',
          autoPlay: true,
          onEnded: () => ended++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(video.value.isPlaying, true);
    video.value = video.value.copyWith(
      position: video.value.duration,
      isPlaying: false,
    );
    await tester.pumpAndSettle();
    await video.pause();
    await tester.pump();
    expect(ended, 1);
  });

  testWidgets('disk failure does not block playback or discard a note draft', (
    tester,
  ) async {
    final repository = MemoryVideoStudyRepository()..failWrites = true;
    final video = FakeVideoController();
    addTearDown(video.dispose);
    await tester.pumpWidget(
      _app(
        repository,
        StudyVideoPlayer(
          showStudyPanel: true,
          controller: video,
          lessonId: 'lesson',
          source: 'video-v1',
          title: 'Lesson',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Play').first);
    await tester.pump();
    expect(video.value.isPlaying, true);
    await tester.tap(find.text('My notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add note'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Keep draft after failure',
    );
    await tester.ensureVisible(find.byTooltip('Save note'));
    await tester.tap(find.byTooltip('Save note'));
    await tester.pumpAndSettle();
    expect(find.text('Keep draft after failure'), findsOneWidget);
    expect(find.text('Could not save note. Please retry.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

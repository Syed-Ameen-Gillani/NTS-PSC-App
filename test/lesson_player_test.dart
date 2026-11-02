import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/repositories/lesson_player_repository.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/in_video_quiz_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_playback_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/lesson_player_screen.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/video_fullscreen_screen.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/in_video_quiz_dialog.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/professional_video_player.dart';
import 'support/fake_video_controller.dart';

void main() {
  group('MockLessonPlayerRepository Unit Tests', () {
    late MockLessonPlayerRepository repo;

    setUp(() {
      repo = MockLessonPlayerRepository();
    });

    test('getInVideoQuizzes returns seed quizzes for AJK constitution', () async {
      final quizzes = await repo.getInVideoQuizzes('default');
      expect(quizzes.isNotEmpty, isTrue);
      expect(quizzes.first.timestampSeconds, equals(374)); // 06:14
      expect(quizzes.first.topic, contains('AJK Constitution'));
    });

    test('submitInVideoQuiz evaluates answers and returns rationale', () async {
      // Option 2 is correct (Section 12 executive authority)
      final correctResult = await repo.submitInVideoQuiz(
        quizId: 'quiz_ajk_01',
        selectedOptionIndex: 2,
      );
      expect(correctResult.isCorrect, isTrue);
      expect(correctResult.explanation, contains('Section 12'));

      // Option 0 is incorrect
      final wrongResult = await repo.submitInVideoQuiz(
        quizId: 'quiz_ajk_01',
        selectedOptionIndex: 0,
      );
      expect(wrongResult.isCorrect, isFalse);
      expect(wrongResult.hint, isNotEmpty);
    });

    test('savePersonalNote and getPersonalNote persist note in memory', () async {
      await repo.savePersonalNote('test_lesson', 'Key points for test exam');
      final note = await repo.getPersonalNote('test_lesson');
      expect(note, isNotNull);
      expect(note!.content, equals('Key points for test exam'));
    });

    test('postQuestion and getDiscussions optimistic addition', () async {
      final newQuestion = await repo.postQuestion(
        lessonId: 'default',
        question: 'What is the quorum for assembly sessions?',
        studentName: 'Candidate Ali',
      );
      expect(newQuestion.question, contains('quorum'));

      final discussions = await repo.getDiscussions('default');
      expect(discussions.first.question, contains('quorum'));
    });

    test('markLessonCompleted tracks status', () async {
      final initialStatus = await repo.isLessonCompleted(courseId: 'c1', lessonId: 'l1');
      expect(initialStatus, isFalse);

      await repo.markLessonCompleted(courseId: 'c1', lessonId: 'l1');
      final updatedStatus = await repo.isLessonCompleted(courseId: 'c1', lessonId: 'l1');
      expect(updatedStatus, isTrue);
    });
  });

  group('LessonPlaybackNotifier State Tests', () {
    test('Initial state reflects 06:14 and 25:00', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(lessonPlaybackControllerProvider);
      expect(state.positionSeconds, equals(374)); // 06:14
      expect(state.durationSeconds, equals(1500)); // 25:00
      expect(state.formattedPosition, equals('06:14'));
      expect(state.formattedDuration, equals('25:00'));
      expect(state.isPlaying, isFalse);
    });

    test('play, pause, and togglePlayPause update state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(lessonPlaybackControllerProvider.notifier);
      notifier.play();
      expect(container.read(lessonPlaybackControllerProvider).isPlaying, isTrue);

      notifier.pause();
      expect(container.read(lessonPlaybackControllerProvider).isPlaying, isFalse);

      notifier.togglePlayPause();
      expect(container.read(lessonPlaybackControllerProvider).isPlaying, isTrue);
    });

    test('Anti-skip guard triggers checkpoint when skipping ahead', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(lessonPlaybackControllerProvider.notifier);
      notifier.seekToSeconds(100, allowSkipGuard: false);
      expect(container.read(lessonPlaybackControllerProvider).positionSeconds, equals(100));

      // Attempt to jump past 374 without completing quiz
      notifier.seekToSeconds(500, allowSkipGuard: true);

      final state = container.read(lessonPlaybackControllerProvider);
      expect(state.positionSeconds, equals(374));
      expect(state.activeQuizTriggerId, equals('quiz_ajk_01'));
      expect(state.isPlaying, isFalse);
    });
  });

  group('InVideoQuizNotifier State Tests', () {
    test('triggers quiz and evaluates answer', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final quizNotifier = container.read(inVideoQuizControllerProvider.notifier);
      await quizNotifier.loadQuizzes('default');

      quizNotifier.triggerQuizById('quiz_ajk_01');
      expect(container.read(inVideoQuizControllerProvider).isQuizActive, isTrue);

      // Select correct option 2
      quizNotifier.selectOption(2);
      expect(container.read(inVideoQuizControllerProvider).selectedOptionIndex, equals(2));

      final result = await quizNotifier.submitAnswer();
      expect(result, isNotNull);
      expect(result!.isCorrect, isTrue);
      expect(container.read(inVideoQuizControllerProvider).completedQuizIds.contains('quiz_ajk_01'), isTrue);
    });
  });

  group('LessonPlayerScreen & InVideoQuizDialog Widget Tests', () {
    testWidgets('renders LessonPlayerScreen with video controls and tabs', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            builder: (_, __) => const MaterialApp(
              home: LessonPlayerScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title and instructor
      expect(find.text('AJK PSC General Recruitment Masterclass'), findsOneWidget);
      expect(find.text('AJK Interim Constitution Act 1974'), findsOneWidget);
      expect(find.textContaining('Dr. Usman'), findsOneWidget);

      // Verify Tabs
      expect(find.text('Study Notes'), findsOneWidget);
      expect(find.text('Syllabus'), findsOneWidget);
      expect(find.text('Discussion'), findsOneWidget);

      // Verify Study Notes content
      expect(find.text('Lecture Overview'), findsOneWidget);
      expect(find.text('Course Files'), findsOneWidget);
      expect(find.text('Mark Lesson as Completed'), findsOneWidget);
    });

    testWidgets('InVideoQuizDialog interactive choice and submission', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final quizNotifier = container.read(inVideoQuizControllerProvider.notifier);
      await quizNotifier.loadQuizzes('default');
      quizNotifier.triggerQuizById('quiz_ajk_01');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            builder: (_, __) => const MaterialApp(
              home: Scaffold(
                body: InVideoQuizDialog(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Knowledge Check badge and question
      expect(find.textContaining('KNOWLEDGE CHECK'), findsOneWidget);
      expect(find.textContaining('Under the AJK Interim Constitution Act 1974'), findsOneWidget);
      expect(find.text('Check Answer'), findsOneWidget);

      // Tap Option C (index 2)
      final optionFinder = find.textContaining('The President, exercised directly');
      expect(optionFinder, findsOneWidget);
      await tester.ensureVisible(optionFinder);
      await tester.tap(optionFinder);
      await tester.pumpAndSettle();

      // Tap Check Answer
      final checkButton = find.text('Check Answer');
      await tester.ensureVisible(checkButton);
      await tester.tap(checkButton);
      await tester.pumpAndSettle();

      // Verify result explanation and Continue button
      expect(find.textContaining('Correct! Well done.'), findsOneWidget);
      expect(find.text('Continue Video ▶'), findsOneWidget);
    });

    testWidgets('VideoFullscreenScreen renders in landscape with exit button and controls', (tester) async {
      final fakeController = FakeVideoController();
      addTearDown(fakeController.dispose);

      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(812, 375),
            minTextAdapt: true,
            builder: (_, __) => MaterialApp(
              home: VideoFullscreenScreen(
                session: VideoPlayerSession(
                  controller: fakeController,
                  title: 'AJK Interim Constitution Act 1974',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AJK Interim Constitution Act 1974'), findsOneWidget);
      expect(find.byIcon(Icons.replay_10), findsOneWidget);
      expect(find.byIcon(Icons.forward_10), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
    });
  });
}

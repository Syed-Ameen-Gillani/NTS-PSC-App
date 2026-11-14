import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'package:nts_psc_app/features/learn/data/lesson_media_repository.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_video_preview_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_lesson_media_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MediaRepository extends LessonMediaRepository {
  _MediaRepository()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  String status = 'needs_review';
  Completer<void>? publishing;
  List<Map<String, dynamic>>? saved;
  bool failSave = false;
  bool empty = false;
  bool replacement = false;
  String? mediaError;
  String? deletedMediaId;

  @override
  Future<bool> deleteVideo(String mediaId) async {
    deletedMediaId = mediaId;
    empty = true;
    return true;
  }

  @override
  Future<List<LessonMedia>> listForLesson(
    String id, {
    bool includeUnreleased = false,
  }) async {
    if (empty) return [];
    final media = [
      LessonMedia(
        id: 'media',
        lessonId: id,
        path: 'lesson.mp4',
        status: status,
        segments:
            saved ??
            [
              {'start': 0, 'end': 30, 'text': 'Original transcript'},
            ],
        error: mediaError,
        byteSize: 100,
      ),
    ];
    if (replacement) {
      media.add(
        LessonMedia(
          id: 'current-media',
          lessonId: id,
          path: 'old.mp4',
          status: 'ready',
          segments: const [],
          error: null,
          byteSize: 100,
          isCurrent: true,
        ),
      );
    }
    return media;
  }

  @override
  Future<void> saveTranscript(
    String id,
    List<Map<String, dynamic>> segments,
    String language,
  ) async {
    if (failSave) throw StateError('Temporary failure');
    saved = segments;
  }

  @override
  Future<void> publish(String id) async {
    await publishing?.future;
    status = 'ready';
  }
}

Future<void> _open(
  WidgetTester tester,
  _MediaRepository repository, {
  bool moduleAssessment = false,
  bool handout = false,
  bool settle = true,
  QuizModel? linkedQuiz,
  bool missingQuiz = false,
  GoRouter? router,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (handout)
          curriculumMaterialsProvider(
            const CurriculumScope(lessonId: 'lesson'),
          ).overrideWith(
            (ref) async => const [
              CurriculumMaterial(
                id: 'handout',
                title: 'Reading.pdf',
                path: 'reading.pdf',
                sizeBytes: 1024,
              ),
            ],
          ),
        if (moduleAssessment)
          curriculumVisibleAssessmentsProvider(
            const CurriculumScope(lessonId: 'lesson'),
          ).overrideWith(
            (ref) async => [
              (
                assessment: const CurriculumAssessment(
                  id: 'module-link',
                  assessmentId: 'quiz',
                  title: 'Module review quiz',
                  kind: 'quiz',
                  status: 'published',
                ),
                scope: const CurriculumScope(
                  courseId: 'course',
                  moduleId: 'module',
                ),
              ),
            ],
          ),
        if (linkedQuiz != null || missingQuiz)
          curriculumQuizProvider(
            'quiz',
          ).overrideWith((ref) async => linkedQuiz),
        lessonMediaRepositoryProvider.overrideWithValue(repository),
        teacherVideoPreviewProvider('lesson.mp4').overrideWith(
          (ref) async => throw StateError('Preview unavailable in test'),
        ),
        teacherVideoPreviewProvider('old.mp4').overrideWith(
          (ref) async => throw StateError('Preview unavailable in test'),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => router == null
            ? MaterialApp(
                home: TeacherLessonMediaScreen(
                  lesson: LessonModel(
                    id: 'lesson',
                    title: 'Saved lesson',
                    durationMinutes: 1,
                  ),
                ),
              )
            : MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  setUp(() => AppConfig.isSupabaseEnabled = false);

  testWidgets('empty video tab shows one upload card without attached panel', (
    tester,
  ) async {
    await _open(tester, _MediaRepository()..empty = true);
    expect(find.text('Upload Lecture Video'), findsOneWidget);
    expect(find.text('Upload video'), findsOneWidget);
    expect(find.text('No Video Uploaded Yet'), findsNothing);
    expect(find.text('ATTACHED VIDEO'), findsNothing);
  });

  testWidgets('lesson studio shows an assessment linked to its module', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _open(
      tester,
      _MediaRepository()..empty = true,
      moduleAssessment: true,
    );
    await tester.tap(find.widgetWithText(Tab, 'Assessments'));
    await tester.pumpAndSettle();
    expect(find.text('Module review quiz'), findsOneWidget);
    expect(find.text('Quiz | Module | PUBLISHED'), findsOneWidget);
    expect(find.text('Link quiz'), findsOneWidget);
    expect(find.text('Assignment'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Link quiz'),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text('Assignment'),
        matching: find.byType(OutlinedButton),
      ),
      findsOneWidget,
    );
    expect(find.text('Link Assessments & Practice'), findsNothing);
  });

  testWidgets('tapping a published linked quiz opens its analysis page', (
    tester,
  ) async {
    final quiz = QuizModel(
      id: 'quiz',
      title: 'Module review quiz',
      category: 'General',
      totalQuestions: 1,
      durationMinutes: 10,
      passingScore: 60,
      courseId: 'course',
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => TeacherLessonMediaScreen(
            lesson: LessonModel(
              id: 'lesson',
              title: 'Saved lesson',
              durationMinutes: 1,
            ),
          ),
        ),
        GoRoute(
          path: AppRoute.teacherQuizAnalysis.path,
          name: AppRoute.teacherQuizAnalysis.name,
          builder: (_, state) => Scaffold(
            body: Text(
              state.extra == quiz ? 'Quiz analysis opened' : 'Wrong quiz',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await _open(
      tester,
      _MediaRepository()..empty = true,
      moduleAssessment: true,
      linkedQuiz: quiz,
      router: router,
    );
    await tester.tap(find.widgetWithText(Tab, 'Assessments'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Module review quiz'));
    await tester.pumpAndSettle();
    expect(find.text('Quiz analysis opened'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('tapping a draft linked quiz opens the quiz editor', (
    tester,
  ) async {
    final quiz = QuizModel(
      id: 'quiz',
      title: 'Module review quiz',
      category: 'General',
      totalQuestions: 1,
      isPublished: false,
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => TeacherLessonMediaScreen(
            lesson: LessonModel(
              id: 'lesson',
              title: 'Saved lesson',
              durationMinutes: 1,
            ),
          ),
        ),
        GoRoute(
          path: AppRoute.teacherCreateQuiz.path,
          name: AppRoute.teacherCreateQuiz.name,
          builder: (_, state) => Scaffold(
            body: Text(
              state.extra == quiz ? 'Quiz editor opened' : 'Wrong quiz',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await _open(
      tester,
      _MediaRepository()..empty = true,
      moduleAssessment: true,
      linkedQuiz: quiz,
      router: router,
    );
    await tester.tap(find.widgetWithText(Tab, 'Assessments'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Module review quiz'));
    await tester.pumpAndSettle();
    expect(find.text('Quiz editor opened'), findsOneWidget);
  });

  testWidgets('a stale quiz link stays on Lesson Studio with an error', (
    tester,
  ) async {
    await _open(
      tester,
      _MediaRepository()..empty = true,
      moduleAssessment: true,
      missingQuiz: true,
    );
    await tester.tap(find.widgetWithText(Tab, 'Assessments'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Module review quiz'));
    await tester.pump();
    expect(
      find.text('This quiz is unavailable. Refresh the assessments.'),
      findsOneWidget,
    );
    expect(find.text('Lesson Studio'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('replacement video clearly preserves the current live video', (
    tester,
  ) async {
    await _open(tester, _MediaRepository()..replacement = true, settle: false);

    expect(find.text('REPLACEMENT NEEDS REVIEW'), findsOneWidget);
    expect(find.text('LIVE FOR STUDENTS'), findsNothing);
    expect(find.byTooltip('Dismiss video status'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss video status'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byTooltip('Dismiss video status'), findsNothing);
  });

  testWidgets('attached handout appears above the compact add action', (
    tester,
  ) async {
    await _open(tester, _MediaRepository()..empty = true, handout: true);
    await tester.tap(find.widgetWithText(Tab, 'Handouts'));
    await tester.pumpAndSettle();
    expect(find.text('Reading.pdf'), findsOneWidget);
    expect(find.text('Add another document'), findsOneWidget);
    expect(find.text('Upload Lecture Handouts'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Add another document')).dy,
      greaterThan(tester.getTopLeft(find.text('Reading.pdf')).dy),
    );
  });

  testWidgets(
    'upload and transcript editing stay on one page without dialogs',
    (tester) async {
      final repository = _MediaRepository();
      await _open(tester, repository);
      expect(
        find.text('Only one video is allowed per lesson.'),
        findsOneWidget,
      );
      expect(find.text('Upload Lecture Video'), findsNothing);
      expect(find.text('ATTACHED VIDEO'), findsOneWidget);
      expect(find.text('Change video'), findsNothing);
      expect(find.byTooltip('Delete video'), findsOneWidget);
      expect(
        tester
            .getTopLeft(find.text('Only one video is allowed per lesson.'))
            .dy,
        greaterThan(tester.getTopLeft(find.text('ATTACHED VIDEO')).dy),
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Original transcript'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Original transcript'),
        'Corrected transcript',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Publish video'),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text('Save transcript'));
      await tester.tap(find.text('Save transcript'));
      await tester.pumpAndSettle();
      expect(repository.saved?.single['text'], 'Corrected transcript');
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Publish video'),
            )
            .onPressed,
        isNotNull,
      );
      expect(find.text('Corrected transcript'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'publishing blocks back and safely rebuilds into published state',
    (tester) async {
      final repository = _MediaRepository()..publishing = Completer<void>();
      await _open(tester, repository);
      await tester.ensureVisible(find.text('Publish video'));
      await tester.tap(find.text('Publish video'));
      await tester.pump();
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, false);
      final back = find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Back',
      );
      expect(tester.widget<IconButton>(back).onPressed, isNull);
      repository.publishing!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Change video'), findsNothing);
      expect(find.byTooltip('Delete video'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed transcript save keeps entered text for retry', (
    tester,
  ) async {
    final repository = _MediaRepository()..failSave = true;
    await _open(tester, repository);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Original transcript'),
      'Keep these corrections',
    );
    await tester.ensureVisible(find.text('Save transcript'));
    await tester.tap(find.text('Save transcript'));
    await tester.pumpAndSettle();
    expect(find.text('Keep these corrections'), findsOneWidget);
    expect(repository.saved, isNull);
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('deleting an attached video requires confirmation', (
    tester,
  ) async {
    final repository = _MediaRepository()..status = 'ready';
    await _open(tester, repository);
    await tester.ensureVisible(find.byTooltip('Delete video'));
    await tester.tap(find.byTooltip('Delete video'));
    await tester.pumpAndSettle();
    expect(find.text('Delete video?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.deletedMediaId, isNull);
    await tester.ensureVisible(find.byTooltip('Delete video'));
    await tester.tap(find.byTooltip('Delete video'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete video'));
    await tester.pumpAndSettle();
    expect(repository.deletedMediaId, 'media');
    expect(find.text('ATTACHED VIDEO'), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('invalid transcript times cannot be saved', (tester) async {
    final repository = _MediaRepository();
    await _open(tester, repository);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'NaN');
    await tester.ensureVisible(find.text('Save transcript'));
    await tester.tap(find.text('Save transcript'));
    await tester.pumpAndSettle();
    expect(repository.saved, isNull);
    expect(find.text('Enter valid seconds'), findsOneWidget);
  });

  testWidgets('transcription failure replaces status and auto-dismisses', (
    tester,
  ) async {
    final repository = _MediaRepository()..mediaError = 'Transcription failed';
    await _open(tester, repository);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TRANSCRIPTION FAILED'), findsOneWidget);
    expect(find.text('TRANSCRIPT REVIEW'), findsNothing);
    expect(find.byTooltip('Dismiss video status'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('TRANSCRIPTION FAILED'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

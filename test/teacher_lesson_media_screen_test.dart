import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
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
  }) async => empty
      ? []
      : [
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
            error: null,
            byteSize: 100,
          ),
        ];

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
        lessonMediaRepositoryProvider.overrideWithValue(repository),
        teacherVideoPreviewProvider('lesson.mp4').overrideWith(
          (ref) async => throw StateError('Preview unavailable in test'),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: TeacherLessonMediaScreen(
            lesson: LessonModel(
              id: 'lesson',
              title: 'Saved lesson',
              durationMinutes: 1,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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

  testWidgets('attached handout appears above the compact add action', (
    tester,
  ) async {
    await _open(tester, _MediaRepository()..empty = true, handout: true);
    await tester.tap(find.widgetWithText(Tab, 'Handouts'));
    await tester.pumpAndSettle();
    expect(find.text('Reading.pdf'), findsOneWidget);
    expect(find.text('Add another handout'), findsOneWidget);
    expect(find.text('Upload Lecture Handouts'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Add another handout')).dy,
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
      expect(find.text('Change video'), findsOneWidget);
      expect(find.byTooltip('Delete video'), findsOneWidget);
      expect(
        (tester.getTopLeft(find.text('Change video')).dy -
                tester.getTopLeft(find.text('ATTACHED VIDEO')).dy)
            .abs(),
        lessThan(24),
      );
      expect(
        tester.getTopLeft(find.text('Only one video is allowed per lesson.')).dy,
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
      expect(find.text('Change video'), findsOneWidget);
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
}

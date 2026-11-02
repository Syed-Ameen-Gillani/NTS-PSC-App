import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_repository.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/course_instructor_provider.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/lesson_authoring_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/course_workspace_module.dart';

class _Teachers extends SupabaseCourseRepository {
  _Teachers(super.client);
  int requests = 0;
  bool fail = false;
  @override
  Future<TeacherModel?> getPublicTeacher(String teacherId) async {
    requests++;
    if (fail) throw StateError('Temporary failure');
    return TeacherModel(
      id: teacherId,
      name: 'Actual instructor',
      subject: 'History',
      imagePath: '',
      qualification: '',
      rating: 0,
      studentCount: 0,
    );
  }
}

void main() {
  test(
    'instructor visits reuse successful data and explicit refresh reloads',
    () async {
      final client = SupabaseClient('https://example.invalid', 'test-key');
      addTearDown(client.dispose);
      final repository = _Teachers(client);
      final container = ProviderContainer(
        overrides: [courseRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final provider = courseInstructorProvider('teacher');
      final first = container.listen(provider, (_, _) {});
      await container.read(provider.future);
      first.close();
      await container.pump();
      final second = container.listen(provider, (_, _) {});
      addTearDown(second.close);
      expect(
        (await container.read(provider.future))?.name,
        'Actual instructor',
      );
      expect(repository.requests, 1);
      container.invalidate(provider);
      await container.read(provider.future);
      expect(repository.requests, 2);
    },
  );

  test(
    'failed instructor lookup is not retained after leaving the tab',
    () async {
      final client = SupabaseClient('https://example.invalid', 'test-key');
      addTearDown(client.dispose);
      final repository = _Teachers(client)..fail = true;
      final container = ProviderContainer(
        overrides: [courseRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final provider = courseInstructorProvider('teacher');
      final sub = container.listen(provider, (_, _) {});
      await expectLater(container.read(provider.future), throwsStateError);
      sub.close();
      await container.pump();
      repository.fail = false;
      final next = container.listen(provider, (_, _) {});
      addTearDown(next.close);
      expect(await container.read(provider.future), isNotNull);
      expect(repository.requests, 2);
    },
  );

  test('documents validate type, nonempty content and the 25 MB limit', () {
    validateCurriculumMaterial('Handout.PDF', maxCurriculumMaterialBytes);
    validateCurriculumMaterial('Slides.pptx', 1);
    expect(() => validateCurriculumMaterial('Bad.exe', 1), throwsArgumentError);
    expect(
      () => validateCurriculumMaterial('Empty.pdf', 0),
      throwsArgumentError,
    );
    expect(
      () => validateCurriculumMaterial(
        'Large.pdf',
        maxCurriculumMaterialBytes + 1,
      ),
      throwsArgumentError,
    );
    expect(
      const CurriculumScope(courseId: 'c', moduleId: 'm'),
      const CurriculumScope(courseId: 'c', moduleId: 'm'),
    );
  });

  test(
    'partial asset failure retries the saved lesson and only remaining files',
    () async {
      var creates = 0, videos = 0;
      final uploads = <String>[];
      var fail = true;
      final input = LessonModel(
        id: 'draft',
        title: 'Lesson',
        durationMinutes: 20,
      );
      final controller = LessonAuthoringController(
        create: (lesson) async {
          creates++;
          return lesson.copyWith(id: 'persisted');
        },
        uploadVideo: (lesson, video, progress) async {
          videos++;
        },
        uploadMaterial: (lesson, file) async {
          if (file.name == 'two.pdf' && fail) {
            fail = false;
            throw StateError('Network');
          }
          uploads.add(file.name);
        },
      );
      const key = (draftId: 'draft', courseId: 'course', moduleId: 'module');
      final container = ProviderContainer(
        overrides: [
          lessonAuthoringProvider.overrideWith((ref, key) => controller),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(lessonAuthoringProvider(key), (_, _) {});
      addTearDown(sub.close);
      container.read(lessonAuthoringProvider(key));
      controller.selectFiles([
        (path: 'one', name: 'one.pdf', sizeBytes: 1),
        (path: 'two', name: 'two.pdf', sizeBytes: 1),
      ]);
      const video = (path: 'video', name: 'video.mp4', mimeType: 'video/mp4');
      await expectLater(controller.save(input, video), throwsStateError);
      expect(
        container.read(lessonAuthoringProvider(key)).saved?.id,
        'persisted',
      );
      expect(
        container.read(lessonAuthoringProvider(key)).files.single.name,
        'two.pdf',
      );
      final saved = await controller.save(input, video);
      expect(saved.id, 'persisted');
      expect(creates, 1);
      expect(videos, 1);
      expect(uploads, ['one.pdf', 'two.pdf']);
    },
  );

  test('double submit cannot create duplicate lessons', () async {
    final pending = Completer<LessonModel>();
    final controller = LessonAuthoringController(
      create: (_) => pending.future,
      uploadVideo: (_, _, _) async {},
      uploadMaterial: (_, _) async {},
    );
    addTearDown(controller.dispose);
    final lesson = LessonModel(
      id: 'draft',
      title: 'Lesson',
      durationMinutes: 20,
    );
    final saving = controller.save(lesson, null);
    await expectLater(controller.save(lesson, null), throwsStateError);
    pending.complete(lesson.copyWith(id: 'saved'));
    expect((await saving).id, 'saved');
  });

  for (final width in [320.0, 768.0]) {
    testWidgets('reading lesson uses a leading document icon at $width', (
      tester,
    ) async {
      AppConfig.isSupabaseEnabled = true;
      addTearDown(() => AppConfig.isSupabaseEnabled = false);
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            curriculumAttachmentSummaryProvider.overrideWith(
              (ref, scope) async => const CurriculumAttachmentSummary(
                handouts: 0,
                quizzes: 0,
                assignments: 0,
              ),
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: CourseWorkspaceModule(
                  courseId: 'course',
                  module: CourseModuleModel(
                    id: 'm',
                    title: 'Module',
                    lessons: [
                      LessonModel(
                        id: 'l',
                        title: 'Dogra raj',
                        durationMinutes: 20,
                      ),
                    ],
                  ),
                  index: 0,
                  onAddLesson: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, '1. Dogra raj'),
      );
      expect(tile.leading, isA<Icon>());
      expect(tile.trailing, isNull);
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_outline), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

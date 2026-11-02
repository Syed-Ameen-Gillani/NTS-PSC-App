import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/course_instructor_provider.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_overview_tab.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_curriculum_tab.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_instructor_tab.dart';
import 'package:nts_psc_app/features/curriculum/domain/lesson_activity.dart';

CourseModel _course({List<CourseModuleModel> modules = const []}) =>
    CourseModel(
      id: 'draft-course',
      title: 'My course',
      author: 'Actual Teacher',
      rating: 0,
      price: 'Free',
      imagePath: '',
      isPublished: false,
      instructorId: 'teacher-id',
      modules: modules,
    );

Widget _app(Widget child) => ProviderScope(
  child: ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, _) => MaterialApp(home: Scaffold(body: child)),
  ),
);

void main() {
  setUp(() => AppConfig.isSupabaseEnabled = true);
  tearDown(() => AppConfig.isSupabaseEnabled = false);

  for (final width in [320.0, 768.0]) {
    testWidgets('empty draft shows no fabricated overview at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _app(CourseOverviewTab(course: _course(), isTeacher: true)),
      );
      await tester.pumpAndSettle();
      expect(find.text('No description added yet.'), findsOneWidget);
      expect(find.text('No topics added yet.'), findsOneWidget);
      expect(find.text('0 Lessons'), findsOneWidget);
      expect(find.text('0 Students'), findsOneWidget);
      expect(find.text('No ratings yet'), findsOneWidget);
      expect(find.textContaining('Customs Act'), findsNothing);
      expect(find.textContaining('Certificate'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('topics and lecture count follow the saved modules', (
    tester,
  ) async {
    final course = _course(
      modules: [
        CourseModuleModel(
          id: 'module',
          title: 'Saved topic',
          lessons: [
            LessonModel(
              id: 'lesson',
              title: 'Saved lesson',
              durationMinutes: 5,
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      _app(CourseOverviewTab(course: course, isTeacher: true)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saved topic'), findsOneWidget);
    expect(find.text('1 Lesson'), findsOneWidget);
    expect(find.text('18 Lessons'), findsNothing);
  });

  testWidgets('empty syllabus contains no sample modules', (tester) async {
    await tester.pumpWidget(
      _app(CourseCurriculumTab(course: _course(), isTeacher: true)),
    );
    expect(find.text('No modules added yet.'), findsOneWidget);
    expect(find.textContaining('Foundations'), findsNothing);
  });

  testWidgets('empty real module contains no sample lessons', (tester) async {
    await tester.pumpWidget(
      _app(
        CourseCurriculumTab(
          course: _course(
            modules: [CourseModuleModel(id: 'm', title: 'My module')],
          ),
          isTeacher: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('My module'), findsOneWidget);
    expect(find.text('No lessons added yet.'), findsOneWidget);
  });

  testWidgets('lesson without video is not presented as playable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        CourseCurriculumTab(
          course: _course(
            modules: [
              CourseModuleModel(
                id: 'm',
                title: 'My module',
                lessons: [
                  LessonModel(
                    id: 'lesson',
                    title: 'Lesson details only',
                    durationMinutes: 25,
                  ),
                ],
              ),
            ],
          ),
          isTeacher: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No learning activities'), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_outline), findsNothing);
    expect(
      tester
          .widget<ListTile>(find.byKey(const ValueKey('open-lesson:lesson')))
          .onTap,
      isNull,
    );
  });

  testWidgets('saved video remains playable', (tester) async {
    await tester.pumpWidget(
      _app(
        CourseCurriculumTab(
          course: _course(
            modules: [
              CourseModuleModel(
                id: 'm',
                title: 'My module',
                lessons: [
                  LessonModel(
                    id: 'lesson',
                    title: 'Hosted lesson',
                    durationMinutes: 25,
                    videoPath: 'teacher/course/lesson.mp4',
                  ),
                ],
              ),
            ],
          ),
          isTeacher: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No video added'), findsNothing);
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    expect(find.text('Video lesson  |  25 min'), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(find.byKey(const ValueKey('open-lesson:lesson')))
          .onTap,
      isNotNull,
    );
  });

  testWidgets('single-activity lesson opens directly without nested arrow', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        CourseCurriculumTab(
          course: _course(
            modules: [
              CourseModuleModel(
                id: 'm',
                title: 'Introduction',
                lessons: [
                  LessonModel(
                    id: 'lesson',
                    title: 'Welcome',
                    durationMinutes: 25,
                    videoPath: 'teacher/course/lesson.mp4',
                    activities: const [
                      LessonActivity(
                        id: 'video',
                        kind: 'video',
                        title: 'Video',
                        order: 0,
                        isRequired: true,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          isTeacher: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ExpansionTile), findsOneWidget);
    expect(find.text('1.1.1 Video'), findsNothing);
    expect(
      tester
          .widget<ListTile>(find.byKey(const ValueKey('open-lesson:lesson')))
          .onTap,
      isNotNull,
    );
  });

  testWidgets(
    'public syllabus lesson is counted but locked before enrollment',
    (tester) async {
      await tester.pumpWidget(
        _app(
          CourseCurriculumTab(
            course: _course(
              modules: [
                CourseModuleModel(
                  id: 'm',
                  title: 'Public module',
                  lessons: [
                    LessonModel(
                      id: 'published',
                      title: 'Published lesson',
                      durationMinutes: 25,
                      isLocked: true,
                    ),
                  ],
                ),
              ],
            ),
            isTeacher: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Published lesson'), findsOneWidget);
      expect(
        find.text('Enroll in this course to open its lessons.'),
        findsOneWidget,
      );
      expect(find.text('No video added'), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(
              find.byKey(const ValueKey('open-lesson:published')),
            )
            .onTap,
        isNull,
      );
    },
  );

  testWidgets(
    'instructor uses persisted profile instead of prototype biography',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            courseInstructorProvider('teacher-id').overrideWith(
              (ref) async => TeacherModel(
                id: 'teacher-id',
                name: 'Actual Teacher',
                subject: 'Math',
                imagePath: '',
                qualification: 'Actual qualification',
                bio: 'My saved biography',
                rating: 0,
                studentCount: 0,
              ),
            ),
          ],
          child: _app(CourseInstructorTab(course: _course())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('My saved biography'), findsOneWidget);
      expect(find.text('Actual qualification'), findsOneWidget);
      expect(find.textContaining('8 years'), findsNothing);
      expect(find.textContaining('Instructor Rating'), findsNothing);
    },
  );
}

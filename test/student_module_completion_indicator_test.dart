import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_curriculum_tab.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/live_lesson_module_group.dart';

Widget _app(Widget child) => ProviderScope(
  child: ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, _) => MaterialApp(home: Scaffold(body: child)),
  ),
);

LessonModel _lesson(String id, {bool complete = false}) => LessonModel(
  id: id,
  title: 'Lesson $id',
  durationMinutes: 10,
  isCompleted: complete,
);

void main() {
  setUp(() => AppConfig.isSupabaseEnabled = false);

  testWidgets('syllabus shows module completion only while contracted', (
    tester,
  ) async {
    final module = CourseModuleModel(
      id: 'syllabus-module',
      title: 'Completed syllabus module',
      lessons: [_lesson('one', complete: true), _lesson('two', complete: true)],
    );
    final course = CourseModel(
      id: 'course',
      title: 'Course',
      author: 'Teacher',
      rating: 0,
      price: 'Free',
      imagePath: '',
      modules: [module],
    );
    await tester.pumpWidget(
      _app(CourseCurriculumTab(course: course, isTeacher: false)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('completed-module-syllabus-module')),
      findsNothing,
    );
    expect(find.text('01'), findsOneWidget);
    await tester.tap(find.text('Completed syllabus module'));
    await tester.pumpAndSettle();

    final completed = find.byKey(
      const ValueKey('completed-module-syllabus-module'),
    );
    expect(completed, findsOneWidget);
    expect(find.text('01'), findsNothing);
    expect(
      tester
          .widget<Icon>(
            find.descendant(of: completed, matching: find.byType(Icon)),
          )
          .color,
      AppColors.success,
    );
  });

  testWidgets('player module completion requires every lesson', (tester) async {
    final first = _lesson('one');
    final second = _lesson('two');
    final module = CourseModuleModel(
      id: 'player-module',
      title: 'Player module',
      lessons: [first, second],
    );

    Future<void> mount(Set<String> completed) => tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: LiveLessonModuleGroup(
            courseId: 'course',
            module: module,
            moduleNumber: 1,
            currentLesson: first,
            completedLessonIds: completed,
            onSelectLesson: (_) {},
          ),
        ),
      ),
    );

    await mount({'one'});
    await tester.pumpAndSettle();
    await tester.tap(find.text('Player module'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('completed-module-player-module')),
      findsNothing,
    );
    expect(find.text('1'), findsOneWidget);

    await mount({'one', 'two'});
    await tester.pumpAndSettle();
    final completed = find.byKey(
      const ValueKey('completed-module-player-module'),
    );
    expect(completed, findsOneWidget);
    expect(
      tester
          .widget<Icon>(
            find.descendant(of: completed, matching: find.byType(Icon)),
          )
          .semanticLabel,
      'Module completed',
    );
  });

  testWidgets('empty modules never appear completed', (tester) async {
    final empty = CourseModuleModel(id: 'empty', title: 'Empty module');
    final course = CourseModel(
      id: 'course',
      title: 'Course',
      author: 'Teacher',
      rating: 0,
      price: 'Free',
      imagePath: '',
      modules: [empty],
    );
    await tester.pumpWidget(
      _app(CourseCurriculumTab(course: course, isTeacher: false)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Empty module'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('completed-module-empty')), findsNothing);
    expect(find.text('01'), findsOneWidget);
  });
}

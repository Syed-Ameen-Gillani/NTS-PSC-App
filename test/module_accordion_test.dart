import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_curriculum_tab.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/live_lesson_module_group.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/course_workspace_module.dart';
import 'package:nts_psc_app/presentation/widgets/module_accordion.dart';

class _Auth extends AuthController {
  @override
  AuthState build() => _account('first');

  AuthState _account(String id) => AuthState(
    isAuthenticated: true,
    user: UserModel(
      id: id,
      name: id,
      email: 'test@example.invalid',
      imagePath: '',
      isPremium: false,
      courses: 0,
      quizzes: 0,
      avgScore: 0,
    ),
  );

  void switchTo(String id) => state = AsyncData(_account(id));
}

final _modules = List.generate(
  3,
  (i) => CourseModuleModel(id: 'module-$i', title: 'Module ${i + 1}'),
);
final _course = CourseModel(
  id: 'course',
  title: 'Course',
  author: 'Teacher',
  rating: 0,
  price: 'Free',
  imagePath: '',
  modules: _modules,
);

Widget _surface(String surface) {
  if (surface == 'syllabus') {
    return CourseCurriculumTab(course: _course, isTeacher: false);
  }
  return ModuleAccordion(
    initialModuleId: _modules.first.id,
    child: ListView(
      children: [
        for (var i = 0; i < _modules.length; i++)
          if (surface == 'studio')
            CourseWorkspaceModule(
              courseId: _course.id,
              module: _modules[i],
              index: i,
              onAddLesson: () {},
            )
          else
            LiveLessonModuleGroup(
              courseId: _course.id,
              module: _modules[i],
              moduleNumber: i + 1,
              currentLesson: LessonModel(
                id: 'none',
                title: '',
                durationMinutes: 0,
              ),
              completedLessonIds: const {},
              onSelectLesson: (_) {},
            ),
      ],
    ),
  );
}

List<bool> _expanded(WidgetTester tester) => tester
    .widgetList<ExpansionTile>(find.byType(ExpansionTile))
    .map((tile) => tile.controller!.isExpanded)
    .toList();

Future<void> _mount(WidgetTester tester, Widget child, {_Auth? auth}) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => auth ?? _Auth())],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(home: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final surface in ['syllabus', 'studio', 'player']) {
    testWidgets('$surface opens only one module and allows closing all', (
      tester,
    ) async {
      await _mount(tester, Scaffold(body: _surface(surface)));
      expect(_expanded(tester), [true, false, false]);
      await tester.tap(find.text('Module 2'));
      await tester.pumpAndSettle();
      expect(_expanded(tester), [false, true, false]);
      await tester.tap(find.text('Module 3'));
      await tester.pumpAndSettle();
      expect(_expanded(tester), [false, false, true]);
      await tester.tap(find.text('Module 3'));
      await tester.pumpAndSettle();
      expect(_expanded(tester), [false, false, false]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'separate screen instances of the same course keep their expansion',
    (tester) async {
      await _mount(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                Expanded(child: _surface('syllabus')),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Other screen')),
                        body: _surface('syllabus'),
                      ),
                    ),
                  ),
                  child: const Text('Open other screen'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Module 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open other screen'));
      await tester.pumpAndSettle();
      expect(_expanded(tester), [true, false, false]);
      await tester.tap(find.text('Module 3'));
      await tester.pumpAndSettle();
      expect(_expanded(tester), [false, false, true]);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(_expanded(tester), [false, true, false]);
    },
  );

  testWidgets(
    'account switching cannot restore another account expansion from PageStorage',
    (tester) async {
      final auth = _Auth();
      await _mount(tester, Scaffold(body: _surface('syllabus')), auth: auth);
      await tester.tap(find.text('Module 2'));
      await tester.pumpAndSettle();
      auth.switchTo('second');
      await tester.pumpAndSettle();
      expect(_expanded(tester), [true, false, false]);
      await tester.tap(find.text('Module 3'));
      await tester.pumpAndSettle();
      expect(_expanded(tester), [false, false, true]);
      auth.switchTo('first');
      await tester.pumpAndSettle();
      expect(_expanded(tester), [true, false, false]);
      await tester.tap(find.text('Module 2'));
      await tester.pumpAndSettle();
      expect(_expanded(tester), [false, true, false]);
      expect(tester.takeException(), isNull);
    },
  );
}

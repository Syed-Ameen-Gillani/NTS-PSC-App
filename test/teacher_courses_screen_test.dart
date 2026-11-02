import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_theme.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_courses_screen.dart';

class _MockTeacherController extends TeacherController {
  _MockTeacherController(this.courses);

  final List<CourseModel> courses;

  @override
  FutureOr<TeacherState> build() => TeacherState(
        stats: TeacherStatsModel(
          totalStudents: 10,
          activeCourses: courses.length,
          totalQuizzes: 0,
          avgRating: 4.8,
          totalEarnings: 'Rs 5000',
        ),
        courses: courses,
      );
}

CourseModel _testCourse({
  required String id,
  required String title,
  required bool isPublished,
}) =>
    CourseModel(
      id: id,
      title: title,
      category: 'General',
      price: 'Rs 1500',
      author: 'Test Instructor',
      rating: 4.5,
      imagePath: '',
      isPublished: isPublished,
      modules: const [],
      enrolledCount: 15,
    );

Widget _testApp(List<CourseModel> courses) => ProviderScope(
      overrides: [
        teacherControllerProvider.overrideWith(
          () => _MockTeacherController(courses),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TeacherCoursesScreen(),
        ),
      ),
    );

void main() {
  setUp(() => AppConfig.isSupabaseEnabled = true);
  tearDown(() => AppConfig.isSupabaseEnabled = false);

  testWidgets('renders top app bar and Published / Drafts tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp([]));
    await tester.pumpAndSettle();

    expect(find.text('Course Studio'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Published'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Drafts'), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
  });

  testWidgets('switches between published and draft courses on tab select', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final courses = [
      _testCourse(id: 'c1', title: 'Published Flutter', isPublished: true),
      _testCourse(id: 'c2', title: 'Draft Python', isPublished: false),
    ];

    await tester.pumpWidget(_testApp(courses));
    await tester.pumpAndSettle();

    // Initially Published tab is selected
    expect(find.text('Published Flutter'), findsOneWidget);
    expect(find.text('Draft Python'), findsNothing);

    // Tap Drafts tab
    await tester.tap(find.widgetWithText(Tab, 'Drafts'));
    await tester.pumpAndSettle();

    expect(find.text('Draft Python'), findsOneWidget);
    expect(find.text('Published Flutter'), findsNothing);
  });
}

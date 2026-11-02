import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/discover/presentation/controllers/discover_controller.dart';
import 'package:nts_psc_app/features/discover/presentation/pages/discover_screen.dart';
import 'package:nts_psc_app/features/discover/presentation/pages/instructors_screen.dart';
import 'package:nts_psc_app/features/home/presentation/pages/new_courses_screen.dart';
import 'package:nts_psc_app/presentation/widgets/new_courses_list.dart';
import 'package:nts_psc_app/presentation/widgets/popular_teachers_list.dart';

class _Discover extends DiscoverController {
  @override
  DiscoverState build() => DiscoverState(
    popularTeachers: List.generate(
      5,
      (index) => TeacherModel(
        id: 'teacher-$index',
        name: 'Instructor ${index + 1}',
        subject: 'General Studies',
        imagePath: AppAssets.teacher1,
      ),
    ),
    recommendedCourses: List.generate(
      5,
      (index) => CourseModel(
        id: 'course-$index',
        title: 'Recommended ${index + 1}',
        author: 'Instructor',
        category: 'General',
        rating: 0,
        price: 'Free',
        imagePath: AppAssets.course1,
      ),
    ),
  );
}

void main() {
  testWidgets(
    'discover previews open complete instructor and recommended lists',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DiscoverScreen()),
          GoRoute(
            path: AppRoute.instructors.path,
            name: AppRoute.instructors.name,
            builder: (_, __) => const InstructorsScreen(),
          ),
          GoRoute(
            path: AppRoute.publicTeacherProfile.path,
            name: AppRoute.publicTeacherProfile.name,
            builder: (_, state) => Scaffold(
              body: Text('Profile: ${(state.extra as TeacherModel).name}'),
            ),
          ),
          GoRoute(
            path: AppRoute.newCourses.path,
            name: AppRoute.newCourses.name,
            builder: (_, state) => NewCoursesScreen(
              section: state.uri.queryParameters['section']!,
            ),
          ),
          GoRoute(
            path: AppRoute.courseDetail.path,
            name: AppRoute.courseDetail.name,
            builder: (_, state) => Scaffold(
              body: Text('Course: ${(state.extra as CourseModel).title}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [discoverControllerProvider.overrideWith(_Discover.new)],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Instructor 3'), findsOneWidget);
      expect(find.text('Instructor 4'), findsNothing);
      expect(find.text('Recommended 4'), findsNothing);
      final instructorsAction = find.descendant(
        of: find.byType(PopularTeachersList),
        matching: find.text('See all'),
      );
      await tester.ensureVisible(instructorsAction);
      await tester.tap(instructorsAction);
      await tester.pumpAndSettle();
      expect(find.byType(InstructorsScreen), findsOneWidget);
      expect(find.text('Instructor 5'), findsOneWidget);
      await tester.tap(find.text('Instructor 4'));
      await tester.pumpAndSettle();
      expect(find.text('Profile: Instructor 4'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();
      final recommendations = find.byWidgetPredicate(
        (widget) =>
            widget is NewCoursesList && widget.title == 'Explore More Courses',
      );
      final coursesAction = find.descendant(
        of: recommendations,
        matching: find.text('See all'),
      );
      await tester.ensureVisible(coursesAction);
      await tester.tap(coursesAction);
      await tester.pumpAndSettle();
      expect(find.text('Explore more courses'), findsOneWidget);
      expect(find.text('5 courses'), findsOneWidget);
      await tester.ensureVisible(find.text('Recommended 5'));
      await tester.tap(find.text('Recommended 5'));
      await tester.pumpAndSettle();
      expect(find.text('Course: Recommended 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/home_controller.dart';
import 'package:nts_psc_app/features/home/presentation/pages/home_screen.dart';
import 'package:nts_psc_app/features/home/presentation/pages/new_courses_screen.dart';
import 'package:nts_psc_app/presentation/widgets/continue_learning_list.dart';
import 'package:nts_psc_app/presentation/widgets/featured_course_list.dart';
import 'package:nts_psc_app/presentation/widgets/new_courses_list.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';

class _EmptyTeacherController extends TeacherController {
  @override
  FutureOr<TeacherState> build() => TeacherState(
    stats: TeacherStatsModel(
      totalStudents: 0,
      activeCourses: 0,
      totalQuizzes: 0,
      avgRating: 0,
      totalEarnings: 'Rs 0',
    ),
  );
}

class _EmptyHomeController extends HomeController {
  @override
  FutureOr<HomeState> build() => HomeState();
}

class _SignedOutAuthController extends AuthController {
  @override
  FutureOr<AuthState> build() => AuthState();
}

class _PopulatedHomeController extends HomeController {
  @override
  FutureOr<HomeState> build() =>
      HomeState(featuredCourses: [_course], newCourses: [_course]);
}

class _ManyCoursesController extends HomeController {
  @override
  FutureOr<HomeState> build() {
    final courses = List.generate(
      5,
      (index) => _course.copyWith(id: '$index', progress: 0.2),
    );
    return HomeState(
      featuredCourses: courses,
      newCourses: courses,
      continueLearningCourses: courses,
    );
  }
}

final _course = CourseModel(
  id: 'published-course',
  title: 'FPSC Preparation',
  author: 'Ayesha Khan',
  rating: 0,
  price: 'Free',
  imagePath: AppAssets.course1,
  category: 'FPSC',
  isFeatured: true,
);

void main() {
  testWidgets(
    'course previews have three items and See All opens the full list',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: AppRoute.newCourses.path,
            name: AppRoute.newCourses.name,
            builder: (_, state) => NewCoursesScreen(
              section: state.uri.queryParameters['section'] ?? 'new',
              category: state.uri.queryParameters['category'],
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeControllerProvider.overrideWith(_ManyCoursesController.new),
            authControllerProvider.overrideWith(_SignedOutAuthController.new),
            teacherControllerProvider.overrideWith(_EmptyTeacherController.new),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FeaturedCourseList>(find.byType(FeaturedCourseList))
            .courses
            .length,
        3,
      );
      expect(
        tester
            .widget<ContinueLearningList>(find.byType(ContinueLearningList))
            .courses
            .length,
        3,
      );
      for (final section in tester.widgetList<NewCoursesList>(
        find.byType(NewCoursesList),
      )) {
        expect(section.courses.length, 3);
        expect(section.onActionPressed, isNotNull);
      }
      final available = find.byWidgetPredicate(
        (widget) =>
            widget is NewCoursesList && widget.title == 'Available Courses',
      );
      final seeAll = find.descendant(
        of: available,
        matching: find.text('See All'),
      );
      await tester.ensureVisible(seeAll);
      await tester.tap(seeAll);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NewCoursesList>(find.byType(NewCoursesList))
            .courses
            .length,
        5,
      );
    },
  );

  testWidgets(
    'dashboard uses fallback banner and hides empty featured section',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeControllerProvider.overrideWith(_EmptyHomeController.new),
            authControllerProvider.overrideWith(_SignedOutAuthController.new),
            teacherControllerProvider.overrideWith(_EmptyTeacherController.new),
          ],
          child: const ScreenUtilInit(
            designSize: Size(375, 812),
            child: MaterialApp(home: HomeScreen()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Featured Courses'), findsNothing);
      expect(find.text('Explore Courses'), findsOneWidget);
      expect(find.text('Interactive Masterclasses'), findsNothing);
      expect(find.text('No courses available'), findsOneWidget);
      expect(
        find.text('Enroll in a course to start learning here.'),
        findsOneWidget,
      );
      expect(find.text('No categories are available yet.'), findsOneWidget);
      expect(
        find.text('New courses will appear here when published.'),
        findsOneWidget,
      );
      expect(find.text('No live classes are scheduled yet.'), findsNothing);
    },
  );

  if (AppConfig.isSupabaseEnabled) {
    testWidgets('live dashboard renders real course cards without a cover', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeControllerProvider.overrideWith(_PopulatedHomeController.new),
            authControllerProvider.overrideWith(_SignedOutAuthController.new),
          ],
          child: const ScreenUtilInit(
            designSize: Size(375, 812),
            child: MaterialApp(home: HomeScreen()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('FPSC Preparation'), findsWidgets);
      expect(find.text('New Courses'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/home_controller.dart';
import 'package:nts_psc_app/features/discover/presentation/controllers/category_courses_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/my_learning_controller.dart';
import 'package:nts_psc_app/presentation/widgets/continue_learning_list.dart';

CourseModel course(String id) => CourseModel(
  id: id,
  title: 'Course $id',
  author: 'Instructor',
  rating: 0,
  price: 'Free',
  imagePath: AppAssets.course1,
  progress: 0.35,
);

class _Auth extends AuthController {
  @override
  AuthState build() => AuthState();
}

class _Learning extends MyLearningController {
  @override
  MyLearningState build() => MyLearningState(
    ongoingCourses: [course('enrolled')],
    completedCourses: [course('finished')],
  );
}

void main() {
  test(
    'live Continue Learning uses the same enrolled ongoing courses as Learn',
    () async {
      AppConfig.isSupabaseEnabled = true;
      addTearDown(() => AppConfig.isSupabaseEnabled = false);
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_Auth.new),
          myLearningControllerProvider.overrideWith(_Learning.new),
          publishedCatalogProvider.overrideWith(
            (ref) async => [course('catalog-only')],
          ),
          featuredCatalogProvider.overrideWith((ref) async => []),
          allCategoriesProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);
      final state = await container.read(homeControllerProvider.future);
      expect(state.continueLearningCourses.map((c) => c.id), ['enrolled']);
      expect(state.continueLearningCourses.single.progress, 0.35);
    },
  );

  testWidgets('each Continue Learning card routes with its own course ID', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: ContinueLearningList(
              courses: [course('first'), course('second')],
            ),
          ),
        ),
        GoRoute(
          path: AppRoute.courseDetail.path,
          name: AppRoute.courseDetail.name,
          builder: (_, state) => Scaffold(
            body: Text('Opened ${state.uri.queryParameters['courseId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('35%'), findsWidgets);
    await tester.tap(find.text('Course first'));
    await tester.pumpAndSettle();
    expect(find.text('Opened first'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Course second'));
    await tester.pumpAndSettle();
    expect(find.text('Opened second'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/discover/presentation/pages/course_search_screen.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/home_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_search_bar.dart';

void main() {
  testWidgets('catalog search loads additional pages on demand', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final courses = List.generate(
      22,
      (index) => CourseModel(
        id: '$index',
        title: 'Course $index',
        author: 'Instructor',
        rating: 0,
        price: 'Free',
        imagePath: AppAssets.course1,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publishedCatalogProvider.overrideWith((ref) async => courses),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => const MaterialApp(home: CourseSearchScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('20 courses shown'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Show more'),
      500,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();
    expect(find.text('22 courses shown'), findsOneWidget);
    expect(find.text('Show more'), findsNothing);
  });

  testWidgets(
    'catalog search filters real fields and clearing restores results',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final courses = [
        for (final item in [
          ('Kashmir Studies', 'AJK PSC', 'Ameen'),
          ('Pakistan Affairs', 'FPSC', 'Sara'),
          ('Everyday Science', 'NTS', 'Ameen'),
        ])
          CourseModel(
            id: item.$1,
            title: item.$1,
            category: item.$2,
            author: item.$3,
            rating: 0,
            price: 'Free',
            imagePath: AppAssets.course1,
          ),
      ];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: CustomSearchBar()),
          ),
          GoRoute(
            path: AppRoute.courseSearch.path,
            name: AppRoute.courseSearch.name,
            builder: (_, __) => const CourseSearchScreen(),
          ),
          GoRoute(
            path: AppRoute.courseDetail.path,
            name: AppRoute.courseDetail.name,
            builder: (_, state) =>
                Scaffold(body: Text((state.extra as CourseModel).title)),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            publishedCatalogProvider.overrideWith((ref) async => courses),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.tap(find.text('Search courses, exams...'));
      await tester.pumpAndSettle();
      expect(find.text('3 courses shown'), findsOneWidget);
      await tester.enterText(find.byType(CourseSearchField), 'Ameen');
    await tester.pump();
    expect(find.text('3 courses shown'), findsNothing);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('2 courses shown'), findsOneWidget);
      await tester.enterText(find.byType(CourseSearchField), 'AJK');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('1 course shown'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('3 courses shown'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

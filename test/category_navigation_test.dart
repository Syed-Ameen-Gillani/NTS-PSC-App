import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/config/routes/go_router.dart';
import 'package:nts_psc_app/core/networks/mock_data_sources.dart';
import 'package:nts_psc_app/features/home/presentation/pages/course_detail_screen.dart';
import 'package:nts_psc_app/main.dart';

void main() {
  test('category counts match the available mock courses', () async {
    final repository = MockCourseRepository();
    final categories = await repository.getCategories();
    for (final category in categories) {
      final courses = await repository.getCoursesByCategory(category.name);
      expect(category.courseCount, courses.length);
      expect(courses, isNotEmpty);
      expect(
        courses.every((course) => course.category == category.name),
        isTrue,
      );
    }
    expect(
      categories.map((category) => category.name),
      containsAll(['CSS', 'PMS', 'FPSC', 'NTS', 'AJK PSC']),
    );
  });

  testWidgets('trending category opens courses and a course detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    appRouter.go(AppRoute.main.path);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final bar = tester.getRect(find.byType(BottomNavigationBar));
    await tester.tapAt(Offset(bar.left + bar.width * 1.5 / 5, bar.center.dy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.ensureVisible(find.text('CSS'));
    await tester.tap(find.text('CSS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('2 courses'), findsOneWidget);
    expect(find.text('Everyday Science Complete Crash Course'), findsOneWidget);
    expect(
      find.text('FPSC Inspector Customs & Intelligence Officer'),
      findsNothing,
    );

    await tester.tap(find.text('Everyday Science Complete Crash Course'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(CourseDetailScreen), findsOneWidget);

    appRouter.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    appRouter.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.ensureVisible(find.text('View All'));
    await tester.tap(find.text('View All'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('All Categories'), findsOneWidget);
    // View All now opens the category grid, not a combined course list.
    expect(find.text('FPSC'), findsOneWidget);
    expect(find.text('NTS'), findsOneWidget);
    expect(find.text('CSS'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_detail_tabs_header.dart';

void main() {
  testWidgets(
    'pinned course tabs retain valid geometry across scroll and rotation',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            home: DefaultTabController(
              length: 2,
              child: Scaffold(
                body: NestedScrollView(
                  headerSliverBuilder: (_, _) => [
                    const SliverAppBar(expandedHeight: 230, pinned: true),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: CourseDetailTabsHeader(
                        TabBar(
                          indicatorWeight: 3.h,
                          tabs: const [
                            Tab(text: 'Overview'),
                            Tab(text: 'Syllabus'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    children: [
                      ListView.builder(
                        itemCount: 50,
                        itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
                      ),
                      const Center(child: Text('Course syllabus')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(NestedScrollView), const Offset(0, -291.3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(852, 393);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Syllabus'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(393, 852);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/curriculum/presentation/course_link_dialog.dart';

void main() {
  final sampleCourses = [
    CourseModel(
      id: 'c1',
      title: 'AJK PSC General Recruitment Masterclass',
      author: 'Dr. Usman',
      rating: 4.9,
      price: 'Rs 3,500',
      imagePath: 'assets/images/course4.jpg',
      category: 'Civil Service',
      modules: [
        CourseModuleModel(
          id: 'm1',
          title: 'Module 1: Constitutional Law',
          lessons: [
            LessonModel(
              id: 'l1',
              title: 'AJK Interim Constitution Act 1974',
              durationMinutes: 25,
            ),
            LessonModel(
              id: 'l2',
              title: 'High Court & Supreme Court Jurisdictions',
              durationMinutes: 30,
            ),
          ],
        ),
        CourseModuleModel(
          id: 'm2',
          title: 'Module 2: Regional Geography',
          lessons: [
            LessonModel(
              id: 'l3',
              title: 'Rivers & Mountain Passes of Kashmir',
              durationMinutes: 20,
            ),
          ],
        ),
      ],
    ),
    CourseModel(
      id: 'c2',
      title: 'FPSC English Essay Crash Course',
      author: 'Prof. Tariq',
      rating: 4.8,
      price: 'Rs 2,500',
      imagePath: 'assets/images/course1.jpg',
      category: 'English',
      modules: [],
    ),
  ];

  Widget buildSheetApp({
    required void Function(LinkScopeSelection?) onResult,
  }) {
    return ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final res = await showModalBottomSheet<LinkScopeSelection>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => HierarchicalCourseLinkSheet(
                        courses: sampleCourses,
                        title: 'Constitutional Law Final Quiz',
                        kind: 'quiz',
                      ),
                    );
                    onResult(res);
                  },
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('HierarchicalCourseLinkSheet links to entire course at Level 1', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    LinkScopeSelection? result;

    await tester.pumpWidget(buildSheetApp(onResult: (res) => result = res));
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verify courses are rendered
    expect(find.text('AJK PSC General Recruitment Masterclass'), findsOneWidget);
    expect(find.text('FPSC English Essay Crash Course'), findsOneWidget);

    // Tap first course
    await tester.tap(find.text('AJK PSC General Recruitment Masterclass'));
    await tester.pumpAndSettle();

    // Verify Level 1 View
    expect(find.text('Link to Entire Course'), findsOneWidget);
    expect(find.text('Module 1: Constitutional Law'), findsOneWidget);

    // Tap "Attach" at course level
    await tester.tap(find.widgetWithText(FilledButton, 'Attach'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.scope.courseId, 'c1');
    expect(result!.scope.moduleId, isNull);
    expect(result!.scope.lessonId, isNull);
    expect(result!.targetLabel, 'AJK PSC General Recruitment Masterclass');
  });

  testWidgets('HierarchicalCourseLinkSheet links to a specific lesson at Level 2', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    LinkScopeSelection? result;

    await tester.pumpWidget(buildSheetApp(onResult: (res) => result = res));
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Tap course
    await tester.tap(find.text('AJK PSC General Recruitment Masterclass'));
    await tester.pumpAndSettle();

    // Tap Module 1 tile to drill down into lessons
    await tester.tap(find.text('Module 1: Constitutional Law'));
    await tester.pumpAndSettle();

    // Verify Level 2 View
    expect(find.text('Link to Entire Module'), findsOneWidget);
    expect(find.text('AJK Interim Constitution Act 1974'), findsOneWidget);
    expect(find.text('High Court & Supreme Court Jurisdictions'), findsOneWidget);

    // Link the first lesson
    final linkLessonButtons = find.widgetWithText(FilledButton, 'Link Lesson');
    expect(linkLessonButtons, findsNWidgets(2));
    await tester.ensureVisible(linkLessonButtons.first);
    await tester.tap(linkLessonButtons.first);
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.scope.courseId, 'c1');
    expect(result!.scope.moduleId, 'm1');
    expect(result!.scope.lessonId, 'l1');
    expect(result!.targetLabel, 'AJK Interim Constitution Act 1974');
  });

  testWidgets('HierarchicalCourseLinkSheet back button navigates up the hierarchy', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSheetApp(onResult: (_) {}));
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Select course
    await tester.tap(find.text('AJK PSC General Recruitment Masterclass'));
    await tester.pumpAndSettle();
    expect(find.text('OR SELECT SPECIFIC MODULE'), findsOneWidget);

    // Select module
    await tester.tap(find.text('Module 1: Constitutional Law'));
    await tester.pumpAndSettle();
    expect(find.text('OR SELECT SPECIFIC LESSON'), findsOneWidget);

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text('OR SELECT SPECIFIC MODULE'), findsOneWidget);

    // Tap back button again
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text('FPSC English Essay Crash Course'), findsOneWidget);
  });
}

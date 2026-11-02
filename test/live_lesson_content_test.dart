import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/live_lesson_content.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';

void main() {
  final lessons = [
    LessonModel(
      id: 'lesson-1',
      title: 'Welcome to Kashmir Studies',
      durationMinutes: 25,
      notes: 'An introduction to the course and its learning outcomes.',
    ),
    LessonModel(
      id: 'lesson-2',
      title: 'Historical and constitutional background',
      durationMinutes: 32,
    ),
  ];
  final course = CourseModel(
    id: 'course-1',
    title: 'Kashmir Studies',
    author: 'Ameen Gillani',
    rating: 0,
    price: 'Free',
    imagePath: '',
    category: 'AJK PSC',
    modules: [
      CourseModuleModel(
        id: 'module-1',
        title: 'First Module',
        lessons: lessons,
      ),
    ],
  );

  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('lesson content stays aligned at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: LiveLessonContent(
                    course: course,
                    lesson: lessons.first,
                    lessons: lessons,
                    completedLessonIds: const {},
                    currentIndex: 0,
                    savingProgress: false,
                    autoplay: false,
                    onSelectLesson: (_) {},
                    onMarkComplete: () {},
                    onAutoplayChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Welcome to Kashmir Studies'), findsWidgets);
      expect(find.text('Complete'), findsOneWidget);
      expect(find.text('Read lesson'), findsOneWidget);
      expect(find.text('Materials'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Play the next lesson automatically'), findsOneWidget);
      expect(find.text('Course curriculum'), findsOneWidget);
      expect(find.text('First Module'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('completion status is disabled and turns green when complete', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LiveLessonContent(
                  course: course,
                  lesson: lessons.first,
                  lessons: lessons,
                  completedLessonIds: {'lesson-1'},
                  currentIndex: 0,
                  savingProgress: false,
                  autoplay: false,
                  onSelectLesson: (_) {},
                  onMarkComplete: () {},
                  onAutoplayChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final status = find.byKey(const ValueKey('lesson-completion-status'));
    expect(status, findsOneWidget);
    expect(
      tester
          .widget<InkWell>(
            find.descendant(of: status, matching: find.byType(InkWell)),
          )
          .onTap,
      isNull,
    );
    expect(
      tester
          .widget<Text>(
            find.descendant(of: status, matching: find.text('Completed')),
          )
          .style
          ?.color,
      AppColors.success,
    );
  });

  testWidgets('instructor preview retains learner controls without actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LiveLessonContent(
                  course: course,
                  lesson: lessons.first,
                  lessons: lessons,
                  completedLessonIds: const {},
                  currentIndex: 0,
                  savingProgress: false,
                  autoplay: false,
                  onSelectLesson: (_) {},
                  onMarkComplete: () {},
                  onAutoplayChanged: (_) {},
                  isInstructorPreview: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    for (final label in [
      'Materials',
      'Download',
      'Complete',
      'Read lesson',
      'Autoplay',
    ]) {
      expect(find.text(label), findsOneWidget);
      expect(
        tester
            .widget<IgnorePointer>(
              find
                  .ancestor(
                    of: find.text(label),
                    matching: find.byType(IgnorePointer),
                  )
                  .first,
            )
            .ignoring,
        isTrue,
      );
    }
    expect(find.text('Course curriculum'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('curriculum shows only the current lesson module', (
    tester,
  ) async {
    final secondLesson = LessonModel(
      id: 'lesson-3',
      title: 'Modern Kashmir',
      durationMinutes: 20,
    );
    final multiModuleCourse = course.copyWith(
      modules: [
        course.modules.first,
        CourseModuleModel(
          id: 'module-2',
          title: 'Second Module',
          lessons: [secondLesson],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LiveLessonContent(
                  course: multiModuleCourse,
                  lesson: secondLesson,
                  lessons: [...lessons, secondLesson],
                  completedLessonIds: const {},
                  currentIndex: 2,
                  savingProgress: false,
                  autoplay: false,
                  onSelectLesson: (_) {},
                  onMarkComplete: () {},
                  onAutoplayChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Second Module'), findsOneWidget);
    expect(find.text('First Module'), findsNothing);
    expect(find.text('Module 2 · 1 lessons'), findsOneWidget);
  });
}

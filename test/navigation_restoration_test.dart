import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/navigation_extra_codec.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/assessment_creation_request.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/home/domain/course_view_mode.dart';
import 'package:nts_psc_app/features/learn/domain/lesson_player_mode.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/live_lesson_player_screen.dart';
import 'package:nts_psc_app/features/main/presentation/pages/main_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_main_screen.dart';
import 'package:nts_psc_app/presentation/widgets/app_startup.dart';

CourseModel _course() => CourseModel(
  id: 'course-1',
  title: 'Kashmir Studies',
  author: 'Instructor',
  rating: 4,
  price: 'Free',
  imagePath: '',
  modules: [
    CourseModuleModel(
      id: 'module-1',
      title: 'Foundation',
      lessons: [
        LessonModel(
          id: 'lesson-1',
          title: 'First reading',
          durationMinutes: 2,
          notes: 'First notes',
        ),
        LessonModel(
          id: 'lesson-2',
          title: 'Second reading',
          durationMinutes: 3,
          notes: 'Ù…Ø·Ø§Ù„Ø¹Û Ú©Ø´Ù…ÛŒØ±',
        ),
      ],
    ),
  ],
);

void main() {
  const codec = NavigationExtraCodec();
  test(
    'typed course, lesson, mode and authoring scope survive JSON transport',
    () {
      final source = {
        'course': _course(),
        'lesson': _course().modules.first.lessons.last,
        'mode': LessonPlayerMode.learning,
        'viewMode': CourseViewMode.learnerPreview,
        'request': const AssessmentCreationRequest(
          CurriculumScope(courseId: 'course-1', lessonId: 'lesson-2'),
        ),
      };
      final restored =
          codec.decode(jsonDecode(jsonEncode(codec.encode(source))))
              as Map<String, dynamic>;
      final course = restored['course'] as CourseModel;
      expect(
        course.modules.first.lessons.last.notes,
        'Ù…Ø·Ø§Ù„Ø¹Û Ú©Ø´Ù…ÛŒØ±',
      );
      expect((restored['lesson'] as LessonModel).id, 'lesson-2');
      expect(restored['mode'], LessonPlayerMode.learning);
      expect(restored['viewMode'], CourseViewMode.learnerPreview);
      expect(
        (restored['request'] as AssessmentCreationRequest).targetScope.lessonId,
        'lesson-2',
      );
    },
  );

  test('quiz results and assignment dates keep their typed fields', () {
    final quiz = QuizSubmissionResultModel(
      quizId: 'quiz-1',
      quizTitle: 'Quiz',
      score: 1,
      totalQuestions: 1,
      userAnswers: {0: 2},
      questions: [
        QuizQuestionModel(
          id: 'q1',
          questionText: 'Question',
          options: ['a', 'b', 'c'],
          correctOptionIndex: 2,
          explanation: 'Reason',
        ),
      ],
    );
    final restored =
        codec.decode(codec.encode(quiz)) as QuizSubmissionResultModel;
    expect(restored.userAnswers, {0: 2});
    expect(restored.questions.single.options, ['a', 'b', 'c']);
    final due = DateTime.utc(2026, 12, 1);
    final assignment = AssignmentModel(
      id: 'a1',
      courseId: 'course-1',
      courseTitle: 'Course',
      title: 'Essay',
      instructions: 'Read',
      dueAt: due,
    );
    expect(
      (codec.decode(codec.encode(assignment)) as AssignmentModel).dueAt,
      due,
    );
    expect(codec.decode('damaged'), isNull);
    expect(
      codec.decode(codec.encode(Object())),
      isA<TransientNavigationExtra>(),
    );
  });

  testWidgets(
    'typed back stack restores after recreation through async startup',
    (tester) async {
      await tester.pumpWidget(const _RouterHost());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open course'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open lesson'));
      await tester.pumpAndSettle();
      expect(find.text('Second reading'), findsOneWidget);
      await tester.restartAndRestore();
      await tester.pumpAndSettle();
      expect(find.text('Second reading'), findsOneWidget);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Kashmir Studies'), findsOneWidget);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Open course'), findsOneWidget);
    },
  );

  testWidgets(
    'a different account does not claim another account restoration bucket',
    (tester) async {
      await tester.pumpWidget(const _RouterHost());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open course'));
      await tester.pumpAndSettle();
      final saved = await tester.getRestorationData();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const _RouterHost(owner: 'other-account'));
      await tester.pumpAndSettle();
      await tester.restoreFrom(saved);
      await tester.pumpAndSettle();
      expect(find.text('Open course'), findsOneWidget);
      expect(find.text('Open lesson'), findsNothing);
    },
  );

  testWidgets(
    'startup paints before initialization and allows retry on failure',
    (tester) async {
      final ready = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        AppStartup(
          initialize: () {
            calls++;
            return calls == 1 ? ready.future : Future.value();
          },
          child: const MaterialApp(home: Text('Ready')),
        ),
      );
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
      ready.completeError(StateError('Test initialization failure'));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Ready'), findsOneWidget);
      expect(calls, 2);
    },
  );

  testWidgets(
    'current lesson restores when the Riverpod container is recreated',
    (tester) async {
      AppConfig.isSupabaseEnabled = false;
      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              restorationScopeId: 'student',
              home: LiveLessonPlayerScreen(course: _course()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Next item'));
      await tester.tap(find.byTooltip('Next item'));
      await tester.pumpAndSettle();
      expect(find.text('Second reading'), findsWidgets);
      await tester.restartAndRestore();
      await tester.pumpAndSettle();
      expect(find.text('Second reading'), findsWidgets);
      expect(find.text('Item 2 of 2'), findsOneWidget);
    },
  );
  for (final teacher in [false, true]) {
    testWidgets(
      '${teacher ? "teacher" : "student"} main tab survives recreation',
      (tester) async {
        AppConfig.isSupabaseEnabled = false;
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            child: ScreenUtilInit(
              designSize: const Size(375, 812),
              builder: (_, _) => MaterialApp(
                restorationScopeId: 'account',
                home: teacher ? const TeacherMainScreen() : const MainScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .onTap!(2);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
              .currentIndex,
          2,
        );
        await tester.restartAndRestore();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
              .currentIndex,
          2,
        );
      },
    );
  }
}

class _RouterHost extends StatefulWidget {
  const _RouterHost({this.owner = 'student'});
  final String owner;
  @override
  State<_RouterHost> createState() => _RouterHostState();
}

class _RouterHostState extends State<_RouterHost> {
  late final GoRouter router;
  @override
  void initState() {
    super.initState();
    router = GoRouter(
      restorationScopeId: 'navigation',
      extraCodec: const NavigationExtraCodec(),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/course', extra: _course()),
              child: const Text('Open course'),
            ),
          ),
        ),
        GoRoute(
          path: '/course',
          builder: (context, state) {
            final course = state.extra as CourseModel;
            return Scaffold(
              body: Column(
                children: [
                  Text(course.title),
                  TextButton(
                    onPressed: () => context.push(
                      '/lesson',
                      extra: {
                        'course': course,
                        'lesson': course.modules.first.lessons.last,
                      },
                    ),
                    child: const Text('Open lesson'),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back'),
                  ),
                ],
              ),
            );
          },
        ),
        GoRoute(
          path: '/lesson',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>;
            return Scaffold(
              body: Column(
                children: [
                  Text((args['lesson'] as LessonModel).title),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppStartup(
    initialize: () => Future.value(),
    child: MaterialApp.router(
      restorationScopeId: 'cboa-${widget.owner}',
      routerConfig: router,
    ),
  );
}

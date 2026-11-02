import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/config/routes/go_router.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/main.dart';

void main() {
  testWidgets('student quizzes do not expose AI generation', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    appRouter.go(AppRoute.main.path);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final bar = tester.getRect(find.byType(BottomNavigationBar));
    await tester.tapAt(Offset(bar.left + bar.width * 3.5 / 5, bar.center.dy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Assessments'), findsOneWidget);
    expect(find.textContaining('AI Generated'), findsNothing);
    expect(find.text('Generate New'), findsNothing);

    appRouter.go(AppRoute.generateAiQuiz.path);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Teacher access only'), findsOneWidget);
    expect(find.text('Generate Quiz'), findsNothing);
    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('teacher generates a quiz into Assessment Studio', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await container.read(authControllerProvider.future);
      await container
          .read(authControllerProvider.notifier)
          .login('teacher@example.com', 'password', UserRole.teacher);
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    appRouter.go(AppRoute.teacherMain.path);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final bar = tester.getRect(find.byType(BottomNavigationBar));
    await tester.tapAt(Offset(bar.left + bar.width * 2.5 / 4, bar.center.dy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);
    expect(find.byTooltip('Generate AI quiz'), findsOneWidget);
    await tester.tap(find.byTooltip('Generate AI quiz'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('Current Affairs').last);
    await tester.pump();
    await tester.tap(find.text('English Grammar').last);
    await tester.pump();
    await tester.tap(find.text('Hard'));
    await tester.tap(find.byTooltip('Fewer questions'));
    await tester.pump();
    expect(find.text('3'), findsOneWidget);

    for (var index = 0; index < 7; index++) {
      await tester.tap(find.byTooltip('More questions'));
    }
    await tester.pump();
    expect(find.text('10'), findsOneWidget);

    await tester.tap(find.text('Generate Quiz'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 600));

    final quiz = container.read(teacherControllerProvider).value!.quizzes.first;
    expect(quiz.isAiGenerated, isTrue);
    expect(quiz.category, 'English Grammar');
    expect(quiz.difficulty, 'Hard');
    expect(quiz.totalQuestions, 10);
    expect(quiz.questions, hasLength(10));
    await tester.ensureVisible(find.text('Drafts'));
    await tester.pumpAndSettle();
    expect(find.text(quiz.title), findsOneWidget);
    expect(find.text('English Grammar'), findsWidgets);
    expect(
      (await container.read(quizRepositoryProvider).getCourseQuizzes()).any(
        (courseQuiz) => courseQuiz.id == quiz.id,
      ),
      isFalse,
    );
    await tester.pump(const Duration(seconds: 4));
  });
}

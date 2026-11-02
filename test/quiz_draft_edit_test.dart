import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/config/routes/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/main.dart';

void main() {
  testWidgets(
    'editing first draft question retains other questions and settings',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      late QuizModel draft;
      await tester.runAsync(() async {
        await container.read(authControllerProvider.future);
        await container
            .read(authControllerProvider.notifier)
            .login('teacher@example.com', 'password', UserRole.teacher);
        draft = await container
            .read(quizRepositoryProvider)
            .createQuiz(
              QuizModel(
                id: 'draft-test',
                title: 'Multi-question draft',
                category: 'Custom topic',
                difficulty: 'Hard',
                durationMinutes: 20,
                passingScore: 80,
                totalQuestions: 3,
                isPublished: false,
                questions: List.generate(
                  3,
                  (i) => QuizQuestionModel(
                    id: 'question-$i',
                    questionText: 'Question $i',
                    options: const ['A', 'B', 'C', 'D'],
                    correctOptionIndex: i,
                    explanation: 'Explanation $i',
                  ),
                ),
              ),
            );
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MyApp()),
      );
      appRouter.goNamed(AppRoute.teacherMain.name);
      await tester.pumpAndSettle();
      appRouter.pushNamed(AppRoute.teacherCreateQuiz.name, extra: draft);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Question 0'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      final prompt = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.controller?.text == 'Question 0',
      );
      await tester.enterText(prompt, 'Revised question');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Draft Quiz'), findsOneWidget);
      expect(find.text('Revised question'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final saved = await container
          .read(quizRepositoryProvider)
          .getQuizById(draft.id);
      expect(saved!.questions, hasLength(3));
      expect(saved.questions.first.questionText, 'Revised question');
      expect(saved.questions[1], same(draft.questions[1]));
      expect(saved.questions[2], same(draft.questions[2]));
      expect(saved.category, 'Custom topic');
      expect(saved.difficulty, 'Hard');
      expect(saved.passingScore, 80);
      expect(saved.isPublished, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 4));
    },
  );
}

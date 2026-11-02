import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/config/routes/go_router.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_create_quiz_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_quiz_question_screen.dart';
import 'package:nts_psc_app/main.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';

Finder _field(String hint) => find.byWidgetPredicate(
  (widget) => widget is CustomTextFormField && widget.hintText == hint,
);

void main() {
  testWidgets('Add Question opens a page and returns a saved question', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
    appRouter.goNamed(AppRoute.teacherMain.name);
    await tester.pumpAndSettle();
    appRouter.pushNamed(AppRoute.teacherCreateQuiz.name);
    await tester.pumpAndSettle();

    expect(find.byType(TeacherCreateQuizScreen), findsOneWidget);
    expect(find.text('Add questions'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    await tester.tap(find.text('Add questions'));
    await tester.pumpAndSettle();
    expect(find.text('Question 1'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    final promptFocus = tester
        .widget<EditableText>(
          find.descendant(
            of: _field('Write the question'),
            matching: find.byType(EditableText),
          ),
        )
        .focusNode;
    await tester.tap(_field('Write the question'));
    await tester.pump();
    expect(promptFocus.hasFocus, isTrue);
    await tester.tap(find.text('Question 1'));
    await tester.pump();
    expect(promptFocus.hasFocus, isFalse);

    await tester.enterText(_field('Write the question'), 'What is the answer?');
    await tester.enterText(_field('Option A'), 'First');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: _field('Option B'),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );
    await tester.enterText(_field('Option B'), 'Second');
    await tester.enterText(_field('Option C'), 'Third');
    await tester.enterText(_field('Option D'), 'Fourth');
    await tester.tap(find.byType(Radio<int>).at(1));
    await tester.pump();
    expect(
      tester.widget<CustomTextFormField>(_field('Option B')).borderColor,
      AppColors.success,
    );
    expect(
      tester.widget<CustomTextFormField>(_field('Option A')).borderColor,
      isNull,
    );
    await tester.scrollUntilVisible(
      find.text('Next question'),
      180,
      scrollable: find
          .descendant(
            of: find.byType(TeacherQuizQuestionScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Next question'),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(
      _field('Explain why this answer is correct'),
      'Second is correct.',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Next question'));
    expect(
      tester.widget<RadioGroup<int>>(find.byType(RadioGroup<int>)).groupValue,
      1,
    );
    expect(
      tester
          .widget<CustomTextFormField>(_field('Write the question'))
          .controller!
          .text,
      isNotEmpty,
    );
    expect(
      tester.widget<CustomTextFormField>(_field('Option A')).controller!.text,
      isNotEmpty,
    );
    expect(
      tester.widget<CustomTextFormField>(_field('Option B')).controller!.text,
      isNotEmpty,
    );
    expect(
      tester.widget<CustomTextFormField>(_field('Option C')).controller!.text,
      isNotEmpty,
    );
    expect(
      tester.widget<CustomTextFormField>(_field('Option D')).controller!.text,
      isNotEmpty,
    );
    expect(
      tester
          .widget<CustomTextFormField>(
            _field('Explain why this answer is correct'),
          )
          .controller!
          .text,
      isNotEmpty,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Next question'),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Next question'));
    await tester.pumpAndSettle();
    expect(find.text('Question 2'), findsOneWidget);
    expect(_field('Write the question'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('What is the answer?'), findsOneWidget);
    await tester.tap(find.text('What is the answer?'));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('Third'), findsOneWidget);
    expect(find.text('Fourth'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.byTooltip('Add next question'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    await tester.tap(find.byTooltip('Add next question'));
    await tester.pumpAndSettle();
    expect(find.text('Question 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back asks before discarding an unfinished question', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
    appRouter.goNamed(AppRoute.teacherMain.name);
    await tester.pumpAndSettle();
    appRouter.pushNamed(AppRoute.teacherCreateQuiz.name);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add questions'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Write the question'), 'Unfinished question');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Discard question changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Add questions'), findsOneWidget);
  });
}

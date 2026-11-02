import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/config/routes/go_router.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_quiz_studio_screen.dart';
import 'package:nts_psc_app/main.dart';

void main() {
  testWidgets('student assessment tabs load quizzes and assignments', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    appRouter.go(AppRoute.main.path);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final bar = tester.getRect(find.byType(BottomNavigationBar));
    await tester.tapAt(Offset(bar.left + bar.width * 3.5 / 5, bar.center.dy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Quizzes'), findsWidgets);
    expect(find.text('Assignments'), findsWidgets);
    expect(
      find.text('English Grammar & Vocabulary Assessment'),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is CircularProgressIndicator && widget.value == null,
      ),
      findsNothing,
    );

    await tester.tap(find.widgetWithText(Tab, 'Assignments'));
    await tester.pumpAndSettle();
    expect(find.text('Customs Act case study'), findsOneWidget);
  });

  testWidgets('teacher assessment studio uses tabs and two floating actions', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await container.read(authControllerProvider.future);
    });
    container
        .read(authControllerProvider.notifier)
        .selectRole(UserRole.teacher);

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
    expect(find.text('Create Quiz'), findsOneWidget);
    expect(find.text('Quizzes'), findsWidgets);
    expect(find.text('Assignments'), findsWidgets);
    expect(find.text('Published'), findsOneWidget);
    expect(find.text('Drafts'), findsOneWidget);
    await tester.tap(find.byTooltip('Quiz actions').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit draft'), findsNothing);
    expect(find.text('View analysis'), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.text('Pakistan Affairs Draft Mock'), findsOneWidget);
    final draftCard = find.ancestor(
      of: find.text('Pakistan Affairs Draft Mock'),
      matching: find.byType(TeacherQuizListItem),
    );
    await tester.ensureVisible(draftCard);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: draftCard, matching: find.byTooltip('Quiz actions')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit draft'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Draft Quiz'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(Tab, 'Assignments'));
    await tester.pumpAndSettle();
    expect(find.text('Customs Act case study'), findsOneWidget);
    expect(find.text('Published'), findsOneWidget);
    expect(find.text('Drafts'), findsOneWidget);
    expect(find.byTooltip('Generate AI quiz'), findsNothing);
    expect(find.text('Create Quiz'), findsNothing);
    expect(find.byTooltip('Create Assignment'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Quizzes'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Generate AI quiz'), findsOneWidget);
    expect(find.text('Create Quiz'), findsOneWidget);
    expect(find.byTooltip('Create Assignment'), findsNothing);
  });

  testWidgets(
    'both profile roles expose one edit affordance and delete account',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.runAsync(() async {
        await container.read(authControllerProvider.future);
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MyApp()),
      );

      appRouter.go(AppRoute.main.path);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      var bar = tester.getRect(find.byType(BottomNavigationBar));
      await tester.tapAt(Offset(bar.left + bar.width * 4.5 / 5, bar.center.dy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Edit Profile'), findsNothing);
      await tester.ensureVisible(find.text('Delete Account'));
      expect(find.text('Delete Account'), findsOneWidget);

      container
          .read(authControllerProvider.notifier)
          .selectRole(UserRole.teacher);
      appRouter.go(AppRoute.teacherMain.path);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      bar = tester.getRect(find.byType(BottomNavigationBar));
      await tester.tapAt(Offset(bar.left + bar.width * 3.5 / 4, bar.center.dy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byTooltip('Edit profile'), findsOneWidget);
      expect(find.text('Edit Profile'), findsNothing);
      await tester.ensureVisible(find.text('Delete Account'));
      expect(find.text('Delete Account'), findsOneWidget);
    },
  );
}

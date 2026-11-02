import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/config/routes/go_router.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:nts_psc_app/main.dart';

void main() {
  for (final role in [UserRole.student, UserRole.teacher]) {
    testWidgets('${role.label} can edit and save profile', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.runAsync(() async {
        await container.read(authControllerProvider.future);
        await container
            .read(authControllerProvider.notifier)
            .login('${role.name}@example.com', 'password', role);
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MyApp()),
      );
      appRouter.go(
        role == UserRole.teacher
            ? AppRoute.teacherMain.path
            : AppRoute.main.path,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      final tabCount = role == UserRole.teacher ? 4 : 5;
      final bar = tester.getRect(find.byType(BottomNavigationBar));
      await tester.tapAt(
        Offset(
          bar.left + bar.width * (tabCount - 0.5) / tabCount,
          bar.center.dy,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byTooltip('Edit profile'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Edit Profile'), findsOneWidget);
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(role == UserRole.teacher ? 7 : 4));

      await tester.enterText(fields.at(0), 'Updated Name');
      final emailEditor = tester.widget<EditableText>(
        find.descendant(of: fields.at(1), matching: find.byType(EditableText)),
      );
      expect(emailEditor.readOnly, isTrue);
      await tester.enterText(fields.at(2), '+92 300 1234567');
      await tester.enterText(fields.at(3), 'Islamabad, Pakistan');
      if (role == UserRole.teacher) {
        await tester.enterText(fields.at(4), 'Pakistan Affairs');
        await tester.enterText(fields.at(5), 'M.Phil Political Science');
        await tester.enterText(fields.at(6), 'Exam preparation mentor');
      }
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final user = container.read(profileControllerProvider).value!;
      expect(user.name, 'Updated Name');
      expect(user.email, '${role.name}@example.com');
      expect(user.phone, '+92 300 1234567');
      expect(user.location, 'Islamabad, Pakistan');
      if (role == UserRole.teacher) {
        expect(user.subject, 'Pakistan Affairs');
        expect(user.qualification, 'M.Phil Political Science');
        expect(user.bio, 'Exam preparation mentor');
      }
      expect(
        (await container.read(authRepositoryProvider).getCurrentUser())?.name,
        'Updated Name',
      );
      expect(find.text('Updated Name'), findsWidgets);
      await tester.pump(const Duration(seconds: 4));
    });
  }
}

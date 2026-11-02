import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/mock_data_sources.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _RejectingAuthRepository extends MockAuthRepository {
  _RejectingAuthRepository(this.failure);

  final Object failure;

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    throw failure;
  }
}

void main() {
  testWidgets('Next moves focus from email to password', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => const MaterialApp(home: LoginPage()),
        ),
      ),
    );
    await tester.pump();

    final fields = find.byType(TextFormField);
    await tester.tap(fields.at(0));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: fields.at(1),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );
  });

  for (final caseData in [
    (
      AuthException('Invalid login credentials'),
      'Incorrect email or password.',
    ),
    (
      StateError('This account is registered as a Teacher.'),
      'Use the teacher login for this account.',
    ),
  ]) {
    testWidgets('failed login shows ${caseData.$2}', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _RejectingAuthRepository(caseData.$1),
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => const MaterialApp(home: LoginPage()),
          ),
        ),
      );
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'student@example.com');
      await tester.enterText(fields.at(1), 'wrongpassword');
      await tester.ensureVisible(find.text('Log In'));
      await tester.tap(find.text('Log In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(caseData.$2), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });
  }
}

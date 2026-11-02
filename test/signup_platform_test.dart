import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/pages/teacher_signup_screen.dart';
import 'package:nts_psc_app/features/authentication/presentation/pages/signup_create_account_screen.dart';

void main() {
  testWidgets('teacher account link is right-aligned below instructor bio', (
    tester,
  ) async {
    AppConfig.isSupabaseEnabled = false;
    addTearDown(() => AppConfig.isSupabaseEnabled = true);
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) =>
              const MaterialApp(home: TeacherSignupScreen()),
        ),
      ),
    );
    await tester.pump();

    final accountLink = find.text('Already registered as an instructor? ');
    expect(accountLink, findsOneWidget);
    expect(
      find.ancestor(
        of: accountLink,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Align && widget.alignment == Alignment.centerRight,
        ),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(accountLink).dy,
      greaterThan(
        tester.getTopLeft(find.text('Instructor Bio & Experience')).dy,
      ),
    );
    expect(
      tester.getTopLeft(accountLink).dy,
      lessThan(tester.getTopLeft(find.text('Sign Up')).dy),
    );
  });

  testWidgets('signup mirrors account link and iOS-only Apple sign-in', (
    tester,
  ) async {
    AppConfig.isSupabaseEnabled = false;
    addTearDown(() => AppConfig.isSupabaseEnabled = true);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(_signupApp());
    await tester.pump();
    expect(find.text('Already have an account? '), findsOneWidget);
    expect(find.text('Must be at least 8 characters.'), findsNothing);
    expect(
      find.ancestor(
        of: find.text('Already have an account? '),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Align && widget.alignment == Alignment.centerRight,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Continue with Apple'), findsNothing);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(_signupApp(key: const ValueKey('ios-signup')));
    await tester.pump();
    expect(find.text('Continue with Apple'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}

Widget _signupApp({Key? key}) {
  return ProviderScope(
    key: key,
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) =>
          const MaterialApp(home: SignupCreateAccountScreen()),
    ),
  );
}

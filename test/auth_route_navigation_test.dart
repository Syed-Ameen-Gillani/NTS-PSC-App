import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/config/routes/go_router.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';

void main() {
  testWidgets('student signup back navigation returns to student login', (
    tester,
  ) async {
    AppConfig.isSupabaseEnabled = false;
    addTearDown(() => AppConfig.isSupabaseEnabled = true);
    appRouter.go(AppRoute.login.path);
    await tester.pumpWidget(_authApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Create Account'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(appRouter.state.uri.path, AppRoute.login.path);
  });

  testWidgets('teacher signup back navigation returns to teacher login', (
    tester,
  ) async {
    AppConfig.isSupabaseEnabled = false;
    addTearDown(() => AppConfig.isSupabaseEnabled = true);
    appRouter.go(AppRoute.teacherLogin.path);
    await tester.pumpWidget(_authApp(key: const ValueKey('teacher-auth')));
    await tester.pumpAndSettle();

    expect(find.text('Teacher Portal'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Instructor Registration'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Teacher Portal'), findsOneWidget);
    expect(appRouter.state.uri.path, AppRoute.teacherLogin.path);
  });
}

Widget _authApp({Key? key}) {
  return ProviderScope(
    key: key,
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => MaterialApp.router(routerConfig: appRouter),
    ),
  );
}

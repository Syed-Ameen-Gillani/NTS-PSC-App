import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/pages/login_page.dart';

Widget loginApp() => ProviderScope(
  child: ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (context, child) => const MaterialApp(home: LoginPage()),
  ),
);

void main() {
  setUp(() => AppConfig.isSupabaseEnabled = false);
  tearDown(() {
    AppConfig.isSupabaseEnabled = true;
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Apple sign-in is shown only on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(loginApp());
    await tester.pump();
    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(
      KeyedSubtree(key: const ValueKey('ios'), child: loginApp()),
    );
    await tester.pump();
    expect(find.text('Continue with Apple'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('login does not expose a runtime data-source selector', (
    tester,
  ) async {
    await tester.pumpWidget(loginApp());
    await tester.pump();

    expect(find.text('Data source'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Mock'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Supabase'), findsNothing);
  });
}

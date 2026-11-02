import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nts_psc_app/main.dart' as app;
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/config/routes/go_router.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android auth and recovery surfaces run without provider credentials',
    (tester) async {
      await app.main();
      appRouter.goNamed(AppRoute.login.name);
      await tester.pumpAndSettle();
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsNothing);
      appRouter.goNamed(AppRoute.resetPassword.name);
      await tester.pumpAndSettle();
      expect(find.text('Choose a new password'), findsOneWidget);
      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/curriculum/domain/course_pricing.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/course_pricing_field.dart';

void main() {
  test('paid amounts require positive bounded whole PKR', () {
    for (final input in [
      '',
      'Free',
      '0',
      '-1',
      '1.50',
      '1e3',
      '1000001',
      'Rs 2500',
    ]) {
      expect(CoursePricing.parsePaidAmount(input), isNull, reason: input);
    }
    expect(CoursePricing.parsePaidAmount('2500'), 2500);
    expect(CoursePricing.parsePaidAmount('1000000'), 1000000);
  });
  for (final width in [320.0, 768.0]) {
    testWidgets('free/paid validation stays usable at $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: Form(
                  key: key,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CoursePricingField(
                      draftId: 'draft',
                      controller: controller,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(key.currentState!.validate(), true);
      await tester.tap(find.text('Paid'));
      await tester.pumpAndSettle();
      expect(key.currentState!.validate(), false);
      await tester.enterText(find.byType(TextFormField), '2500');
      await tester.pumpAndSettle();
      expect(key.currentState!.validate(), true);
      await tester.tap(find.text('Free'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(key.currentState!.validate(), true);
      expect(tester.takeException(), isNull);
    });
  }
}

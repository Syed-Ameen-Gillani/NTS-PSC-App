import 'package:nts_psc_app/features/auth/presentation/pages/login_page.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/theme/app_theme.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/course_pricing_field.dart';
import 'package:nts_psc_app/presentation/widgets/app_choice_chip.dart';
import 'package:nts_psc_app/presentation/widgets/category_filter_chips.dart';

void _expectUnclippedText(WidgetTester tester, Finder within) {
  for (final paragraph in tester.renderObjectList<RenderParagraph>(
    find.descendant(of: within, matching: find.byType(RichText)),
  )) {
    final text = paragraph.text.toPlainText();
    for (var offset = 0; offset < text.length; offset++) {
      // Line-breaking whitespace may extend beyond a line without painting.
      if (text[offset].trim().isEmpty) continue;
      for (final box in paragraph.getBoxesForSelection(
        TextSelection(baseOffset: offset, extentOffset: offset + 1),
      )) {
        expect(
          box.top,
          greaterThanOrEqualTo(-0.5),
          reason: 'Top clipped for $text',
        );
        expect(
          box.bottom,
          lessThanOrEqualTo(paragraph.size.height + 0.5),
          reason: 'Bottom clipped for $text',
        );
        expect(
          box.left,
          greaterThanOrEqualTo(-0.5),
          reason: 'Left clipped for $text',
        );
        expect(
          box.right,
          lessThanOrEqualTo(paragraph.size.width + 0.5),
          reason: 'Right clipped for $text',
        );
      }
    }
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: 'Label truncated for $text',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter_18pt-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter_18pt-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter_18pt-SemiBold.ttf'));
    await fonts.load();
  });

  for (final size in const [
    Size(320, 568),
    Size(360, 640),
    Size(375, 812),
    Size(412, 915),
    Size(812, 375),
  ]) {
    for (final textScale in [1.0, 1.3, 2.0, 3.0]) {
      for (final adaptive in [false, true]) {
        testWidgets('chip labels fit $size text $textScale adaptive $adaptive', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final scale = math
              .min(size.width / 375, size.height / 812)
              .clamp(0.85, 1.2);
          final designSize = adaptive
              ? Size(size.width / scale, size.height / scale)
              : const Size(375, 812);
          await tester.pumpWidget(
            ScreenUtilInit(
              designSize: designSize,
              builder: (_, _) => MaterialApp(
                theme: AppTheme.lightTheme,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: Scaffold(
                    body: SingleChildScrollView(
                      child: Column(
                        children: [
                          const CategoryFilterChips(
                            filters: ['All', 'AJK PSC', 'FPSC', 'NTS'],
                          ),
                          const CategoryFilterChips(
                            wrap: true,
                            filters: [
                              'Needs action',
                              'Completed',
                              'Awaiting review',
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                AppChoiceChip(
                                  label: const Text('Classroom Management'),
                                  selected: true,
                                  onSelected: (_) {},
                                  labelStyle: AppTextStyles.interRegular14,
                                ),
                                AppChoiceChip(
                                  label: const Text(
                                    'Kashmir Studies — Advanced Reading Skills',
                                  ),
                                  selected: false,
                                  onSelected: (_) {},
                                ),
                                AppActionChip(
                                  label: const Text(
                                    'Provide assignment feedback',
                                  ),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          _expectUnclippedText(tester, find.byType(CategoryFilterChips));
          _expectUnclippedText(tester, find.byType(AppChoiceChip));
          _expectUnclippedText(tester, find.byType(AppActionChip));
        });
      }
    }
  }

  testWidgets('course type pills grow for large labels on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final price = TextEditingController();
    addTearDown(price.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 568),
                textScaler: TextScaler.linear(3),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: CoursePricingField(
                    draftId: 'layout',
                    controller: price,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    _expectUnclippedText(tester, find.byType(CoursePricingField));
  });
  testWidgets('feedback chips wrap inside a dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AlertDialog(
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Wrap(
                  children: [
                    AppActionChip(
                      label: const Text(
                        'Good effort, but missing constitutional references',
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    _expectUnclippedText(tester, find.byType(AppActionChip));
  });

  for (final scale in [1.3, 1.5]) {
    testWidgets('login role labels fit small screens at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              theme: AppTheme.lightTheme,
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(360, 640),
                  textScaler: TextScaler.linear(scale),
                ),
                child: const LoginPage(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      _expectUnclippedText(tester, find.text('Student'));
      _expectUnclippedText(tester, find.text('Teacher'));
    });
  }
}

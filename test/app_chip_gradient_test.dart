import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/theme/app_theme.dart';
import 'package:nts_psc_app/presentation/widgets/app_choice_chip.dart';
import 'package:nts_psc_app/presentation/widgets/category_filter_chips.dart';

void main() {
  testWidgets('gradient chips retain native selection and action callbacks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = false;
    var category = 0;
    var actions = 0;
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: boundaryKey,
                child: ColoredBox(
                  color: Colors.white,
                  child: StatefulBuilder(
                    builder: (context, update) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CategoryFilterChips(
                          onSelected: (value) => category = value,
                        ),
                        AppChoiceChip(
                          label: const Text('Reviews'),
                          selected: selected,
                          onSelected: (value) => update(() => selected = value),
                        ),
                        AppActionChip(
                          label: const Text('Feedback'),
                          onPressed: () => actions++,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(-180, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NTS'));
    await tester.tap(find.text('Reviews'));
    await tester.tap(find.text('Feedback'));
    await tester.pumpAndSettle();
    expect(category, 3);
    expect(selected, isTrue);
    expect(actions, 1);
    expect(tester.widget<ChoiceChip>(find.byType(ChoiceChip)).selected, isTrue);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      // RawChip has its own Material canvas. Guard against it covering the
      // gradient with a pale surface while leaving white selected labels.
      final chip = tester.getRect(find.byType(AppChoiceChip));
      final origin = tester.getTopLeft(find.byKey(boundaryKey));
      final sample = chip.topLeft - origin + Offset(chip.width / 2, 4);
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final offset = (sample.dy.floor() * image.width + sample.dx.floor()) * 4;
      expect(
        rgba!.getUint8(offset + 2) - rgba.getUint8(offset),
        greaterThan(80),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/shared_chip_gradients.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.tap(find.text('Reviews'));
    await tester.pumpAndSettle();
    expect(selected, isFalse);
  });
}

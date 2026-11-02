import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/utils/keyboard_dismissal.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';

void main() {
  testWidgets('shared fields release focus without blocking other controls', (
    tester,
  ) async {
    final first = FocusNode();
    final second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    var tapped = false;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CustomTextFormField(focusNode: first, hintText: 'First'),
                CustomTextFormField(focusNode: second, hintText: 'Second'),
                ElevatedButton(
                  onPressed: () => tapped = true,
                  child: const Text('Outside'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CustomTextFormField).first);
    await tester.pump();
    expect(first.hasFocus, isTrue);

    await tester.tap(find.byType(CustomTextFormField).last);
    await tester.pump();
    expect(first.hasFocus, isFalse);
    expect(second.hasFocus, isTrue);

    await tester.tap(find.text('Outside'));
    await tester.pump();
    expect(second.hasFocus, isFalse);
    expect(tapped, isTrue);
  });

  testWidgets('direct text fields release focus after a touch outside', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                focusNode: focus,
                onTapOutside: dismissKeyboardOnTapOutside,
              ),
              const Expanded(child: ColoredBox(color: Colors.white)),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    await tester.tapAt(const Offset(200, 400));
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });

  testWidgets('dragging a scrollable form dismisses the keyboard', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: keyboardDismissScrollBehavior,
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                focusNode: focus,
                onTapOutside: dismissKeyboardOnTapOutside,
              ),
              Expanded(
                child: ListView(
                  children: List.generate(
                    30,
                    (index) => ListTile(title: Text('Row $index')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isFalse);
  });
}

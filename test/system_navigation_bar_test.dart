import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_theme.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';

void main() {
  const backgroundKey = ValueKey('system-navigation-bar-background');

  Widget app({
    required ThemeData theme,
    Color? background,
    bool keyboard = false,
    Widget? body,
  }) => MaterialApp(
    theme: theme,
    home: MediaQuery(
      data: MediaQueryData(
        padding: const EdgeInsets.only(bottom: 24),
        viewPadding: const EdgeInsets.only(bottom: 24),
        viewInsets: EdgeInsets.only(bottom: keyboard ? 240 : 0),
      ),
      child: AppScaffold(
        backgroundColor: background,
        body: body ?? const SafeArea(child: Text('Screen')),
      ),
    ),
  );

  testWidgets('navigation surface and icons update with the active theme', (
    tester,
  ) async {
    await tester.pumpWidget(app(theme: AppTheme.lightTheme));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ColoredBox>(find.byKey(backgroundKey)).color,
      AppTheme.lightTheme.scaffoldBackgroundColor,
    );
    expect(
      SystemChrome.latestStyle?.systemNavigationBarColor,
      AppTheme.lightTheme.scaffoldBackgroundColor,
    );
    expect(
      SystemChrome.latestStyle?.systemNavigationBarIconBrightness,
      Brightness.dark,
    );
    expect(
      SystemChrome.latestStyle?.systemNavigationBarContrastEnforced,
      isFalse,
    );

    await tester.pumpWidget(app(theme: AppTheme.darkTheme));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ColoredBox>(find.byKey(backgroundKey)).color,
      AppTheme.darkTheme.scaffoldBackgroundColor,
    );
    expect(
      SystemChrome.latestStyle?.systemNavigationBarColor,
      AppTheme.darkTheme.scaffoldBackgroundColor,
    );
    expect(
      SystemChrome.latestStyle?.systemNavigationBarIconBrightness,
      Brightness.light,
    );
  });

  testWidgets('explicit scaffold background takes precedence over theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(theme: AppTheme.darkTheme, background: AppColors.surfaceVariant),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<ColoredBox>(find.byKey(backgroundKey)).color,
      AppColors.surfaceVariant,
    );
    expect(
      SystemChrome.latestStyle?.systemNavigationBarColor,
      AppColors.surfaceVariant,
    );
    expect(
      SystemChrome.latestStyle?.systemNavigationBarDividerColor,
      AppColors.surfaceVariant,
    );
    expect(
      SystemChrome.latestStyle?.systemNavigationBarIconBrightness,
      Brightness.dark,
    );
  });

  testWidgets('keyboard owns its navigation surface without an app overlay', (
    tester,
  ) async {
    await tester.pumpWidget(app(theme: AppTheme.lightTheme, keyboard: true));
    await tester.pumpAndSettle();
    expect(find.byKey(backgroundKey), findsNothing);
    expect(find.text('Screen'), findsOneWidget);
  });

  testWidgets('pushed screen updates the bar and popping restores it', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        theme: AppTheme.lightTheme,
        background: AppColors.surfaceVariant,
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AppScaffold(
                    backgroundColor: Colors.black,
                    appBar: AppBar(title: const Text('Video')),
                    body: const SizedBox.expand(),
                  ),
                ),
              ),
              child: const Text('Open video'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open video'));
    await tester.pumpAndSettle();
    expect(SystemChrome.latestStyle?.systemNavigationBarColor, Colors.black);
    expect(
      SystemChrome.latestStyle?.systemNavigationBarIconBrightness,
      Brightness.light,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      SystemChrome.latestStyle?.systemNavigationBarColor,
      AppColors.surfaceVariant,
    );
  });

  testWidgets(
    'bottom navigation and nested tab scaffolds retain their layout',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(bottom: 24),
              viewPadding: EdgeInsets.only(bottom: 24),
            ),
            child: AppScaffold(
              backgroundColor: AppColors.background,
              body: const AppScaffold(
                backgroundColor: AppColors.surfaceVariant,
                body: Center(child: Text('Tab content')),
              ),
              bottomNavigationBar: const SafeArea(
                child: SizedBox(height: 60, child: Center(child: Text('Tabs'))),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tabs'), findsOneWidget);
      expect(find.text('Tab content'), findsOneWidget);
      expect(
        SystemChrome.latestStyle?.systemNavigationBarColor,
        AppColors.background,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/discover/presentation/controllers/discover_controller.dart';
import 'package:nts_psc_app/features/discover/presentation/pages/discover_screen.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/my_learning_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/my_learning_screen.dart';
import 'package:nts_psc_app/features/quizzes/presentation/controllers/quizzes_controller.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/quizzes_screen.dart';
import 'package:nts_psc_app/presentation/widgets/custom_search_bar.dart';
import 'package:nts_psc_app/presentation/widgets/student_tab_header.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';

class _Auth extends AuthController {
  @override
  AuthState build() => AuthState();
}

class _Discover extends DiscoverController {
  @override
  DiscoverState build() => DiscoverState();
}

class _Learning extends MyLearningController {
  @override
  MyLearningState build() => MyLearningState();
}

class _Quizzes extends QuizzesController {
  @override
  QuizzesState build() => QuizzesState();
}

void main() {
  testWidgets(
    'Discover and editable search scale identically with larger text',
    (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: Scaffold(
              body: Column(
                children: [
                  const CustomSearchBar(includePadding: false),
                  CourseSearchField(
                    hintText: 'Search courses, exams...',
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(CustomSearchBar)),
        tester.getSize(find.byType(CourseSearchField)),
      );
      final shortcut = find.byType(CustomSearchBar);
      final editable = find.byType(CourseSearchField);
      final shortcutOrigin = tester.getTopLeft(shortcut);
      final editableOrigin = tester.getTopLeft(editable);
      for (final target in [
        find.byIcon(Icons.search),
        find.text('Search courses, exams...'),
      ]) {
        final left = find.descendant(of: shortcut, matching: target);
        final right = find.descendant(of: editable, matching: target);
        final reference = tester.getTopLeft(left) - shortcutOrigin;
        final actual = tester.getTopLeft(right) - editableOrigin;
        expect(actual.dx, closeTo(reference.dx, 0.01));
        expect(actual.dy, closeTo(reference.dy, 0.01));
      }
      await tester.tap(
        find.descendant(of: editable, matching: find.byIcon(Icons.search)),
      );
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Discover, Learn and Quizzes share title and search styling', (
    tester,
  ) async {
    AppConfig.isSupabaseEnabled = true;
    addTearDown(() => AppConfig.isSupabaseEnabled = false);
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Rect? titleRect;
    Rect? searchRect;
    TextStyle? style;
    for (final (title, screen) in <(String, Widget)>[
      ('Discover', const DiscoverScreen()),
      ('My Learning', const MyLearningScreen()),
    ]) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_Auth.new),
            discoverControllerProvider.overrideWith(_Discover.new),
            myLearningControllerProvider.overrideWith(_Learning.new),
            quizzesControllerProvider.overrideWith(_Quizzes.new),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(home: screen),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final heading = find.descendant(
        of: find.byType(StudentTabHeader),
        matching: find.text(title),
      );
      final search = title == 'Discover'
          ? find.byType(CustomSearchBar)
          : find.byType(CourseSearchField);
      final currentTitle = tester.getRect(heading);
      final currentSearch = tester.getRect(search);
      if (titleRect == null) {
        titleRect = currentTitle;
        searchRect = currentSearch;
        style = tester.widget<Text>(heading).style;
      } else {
        expect(currentTitle.topLeft, titleRect.topLeft);
        expect(currentTitle.height, titleRect.height);
        expect(currentSearch.left, searchRect!.left);
        expect(currentSearch.width, searchRect.width);
        expect(currentSearch.height, searchRect.height);
        expect(tester.widget<Text>(heading).style, style);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [quizzesControllerProvider.overrideWith(_Quizzes.new)],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => const MaterialApp(home: QuizzesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CourseSearchField), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

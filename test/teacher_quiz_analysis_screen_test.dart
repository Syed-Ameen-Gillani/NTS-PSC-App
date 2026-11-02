import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_theme.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_quiz_analysis_provider.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_quiz_analysis_screen.dart';

final _quiz = QuizModel(
  id: 'quiz-1',
  title: 'Test quiz',
  category: 'Pakistan Affairs',
  totalQuestions: 5,
);

Widget _app(
  TeacherQuizSummary summary, {
  QuizModel? quiz,
  ThemeMode themeMode = ThemeMode.light,
}) => ProviderScope(
  overrides: [
    teacherQuizSummaryProvider(_quiz.id).overrideWith((ref) async => summary),
  ],
  child: ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: TeacherQuizAnalysisScreen(quiz: quiz ?? _quiz),
    ),
  ),
);

void main() {
  setUp(() => AppConfig.isSupabaseEnabled = true);
  tearDown(() => AppConfig.isSupabaseEnabled = false);

  testWidgets('new quiz shows no attempts without a fabricated average', (
    tester,
  ) async {
    await tester.pumpWidget(_app((attempts: 0, averagePercent: 0)));
    await tester.pumpAndSettle();

    expect(find.text('Quiz Analysis'), findsOneWidget);
    expect(find.text('0 attempts'), findsOneWidget);
    expect(
      find.text('Scores will appear after students complete this quiz.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.bar_chart_outlined), findsNothing);
    expect(find.text('Average score'), findsNothing);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final divider = (appBar.bottom! as PreferredSize).child as Container;
    expect(divider.color, AppColors.grey300);
  });

  testWidgets('draft quiz shows the next step without a results card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app((
        attempts: 0,
        averagePercent: 0,
      ), quiz: _quiz.copyWith(isPublished: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 attempts'), findsOneWidget);
    expect(
      find.text('Publish and link this quiz to collect results.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.bar_chart_outlined), findsNothing);
  });

  testWidgets('quiz with attempts shows live summary values', (tester) async {
    await tester.pumpWidget(_app((attempts: 3, averagePercent: 72.5)));
    await tester.pumpAndSettle();

    expect(find.text('Attempts'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Average score'), findsOneWidget);
    expect(find.text('72.5%'), findsOneWidget);
    expect(find.text('Pass mark 60%'), findsOneWidget);
  });

  testWidgets('long title and score panel fit compact dark viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final quiz = QuizModel(
      id: _quiz.id,
      title: 'Pakistan Affairs and Current Events Comprehensive Practice Quiz',
      category: 'Pakistan Affairs and Current Events',
      totalQuestions: 10,
      durationMinutes: 30,
      passingScore: 60,
    );
    await tester.pumpWidget(
      _app(
        (attempts: 12, averagePercent: 72.5),
        quiz: quiz,
        themeMode: ThemeMode.dark,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(quiz.title), findsOneWidget);
    expect(find.text('72.5%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

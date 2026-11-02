import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/theme/app_theme.dart';
import 'package:nts_psc_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:nts_psc_app/features/teacher/domain/models/teacher_insights_models.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_dashboard_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_payouts_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_profile_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/teacher_quick_actions.dart';

class _ProfileController extends ProfileController {
  @override
  FutureOr<UserModel> build() => UserModel(
    id: 'teacher-1',
    name: 'Ayesha Khan',
    email: 'private@example.com',
    imagePath: AppAssets.teacher1,
    isPremium: false,
    courses: 2,
    quizzes: 3,
    avgScore: 0,
    role: UserRole.teacher,
    subject: 'Pakistan Affairs',
    qualification: 'MPhil Political Science',
    bio: 'Helping learners prepare with structured lessons.',
  );
}

class _TeacherController extends TeacherController {
  @override
  FutureOr<TeacherState> build() => TeacherState(
    stats: TeacherStatsModel(
      totalStudents: 1,
      activeCourses: 2,
      totalQuizzes: 3,
      avgRating: 0,
      totalEarnings: 'Rs 0',
    ),
    recentEnrollments: [
      RecentEnrollmentModel(
        id: 'enrollment-1',
        studentName: 'Ali Raza',
        courseTitle: 'FPSC Preparation',
        enrolledAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ],
  );
}

Widget _app(Widget child, {Size designSize = const Size(375, 812)}) =>
    ProviderScope(
      overrides: [
        profileControllerProvider.overrideWith(_ProfileController.new),
        teacherControllerProvider.overrideWith(_TeacherController.new),
      ],
      child: ScreenUtilInit(
        designSize: designSize,
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) =>
            MaterialApp(theme: AppTheme.lightTheme, home: child),
      ),
    );

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('teacher dashboard renders real enrollment on compact phone', (
    tester,
  ) async {
    await _setViewport(tester, const Size(320, 568));
    await tester.pumpWidget(_app(const TeacherDashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Ayesha Khan'), findsOneWidget);
    expect(find.text('Educora Studio'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Assignment'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    final courseTop = tester
        .getTopLeft(find.widgetWithText(FilledButton, 'Create course'))
        .dy;
    final quizTop = tester
        .getTopLeft(find.widgetWithText(OutlinedButton, 'Quiz'))
        .dy;
    final assignmentTop = tester
        .getTopLeft(find.widgetWithText(OutlinedButton, 'Assignment'))
        .dy;
    expect(courseTop, lessThan(quizTop));
    expect(quizTop, assignmentTop);
    expect(find.text('View analytics'), findsOneWidget);
    expect(
      (tester.getCenter(find.text('Studio overview')).dy -
              tester.getCenter(find.text('View analytics')).dy)
          .abs(),
      lessThan(3),
    );
    await tester.scrollUntilVisible(
      find.text('Ali Raza'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ali Raza'), findsOneWidget);
    expect(find.text('FPSC Preparation'), findsOneWidget);
    expect(
      (tester.getCenter(find.text('Recent enrollments')).dy -
              tester.getCenter(find.text('View learners')).dy)
          .abs(),
      lessThan(3),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick actions remain tappable on tablet', (tester) async {
    await _setViewport(tester, const Size(1024, 768));
    final invoked = <String>[];
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: TeacherQuickActions(
            onCreateCourse: () => invoked.add('course'),
            onCreateQuiz: () => invoked.add('quiz'),
            onCreateAssignment: () => invoked.add('assignment'),
          ),
        ),
        designSize: const Size(853, 640),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create course'));
    await tester.tap(find.text('Quiz'));
    await tester.tap(find.text('Assignment'));
    expect(invoked, ['course', 'quiz', 'assignment']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('teacher profile omits duplicate overview and email on tablet', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1024, 768));
    await tester.pumpWidget(
      _app(const TeacherProfileScreen(), designSize: const Size(853, 640)),
    );
    await tester.pumpAndSettle();

    expect(find.text('private@example.com'), findsNothing);
    expect(find.text('My Courses'), findsNothing);
    expect(find.text('Learners'), findsNothing);
    expect(find.text('Assessments'), findsNothing);
    expect(find.text('View analytics'), findsNothing);
    expect(find.text('Ayesha Khan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'payout screen shows backend zero state without fake withdrawal',
    (tester) async {
      await _setViewport(tester, const Size(375, 812));
      await tester.pumpWidget(_app(const TeacherPayoutsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Rs 0'), findsWidgets);
      expect(find.text('No payouts yet'), findsOneWidget);
      expect(
        find.text('Withdrawals available after PayFast setup'),
        findsOneWidget,
      );
      expect(find.textContaining('initiated'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

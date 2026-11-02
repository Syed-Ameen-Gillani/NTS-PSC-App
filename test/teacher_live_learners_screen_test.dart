import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_theme.dart';
import 'package:nts_psc_app/features/teacher/domain/models/teacher_insights_models.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_learner_roster_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_students_screen.dart';

class _Teacher extends TeacherController {
  @override
  FutureOr<TeacherState> build() => TeacherState(
    stats: TeacherStatsModel(
      totalStudents: 1,
      activeCourses: 1,
      totalQuizzes: 0,
      avgRating: 0,
      totalEarnings: 'Rs 0',
    ),
    courses: [
      CourseModel(
        id: 'course-1',
        title: 'Kashmir Studies',
        author: 'Teacher',
        rating: 0,
        price: 'Free',
        imagePath: '',
        enrolledCount: 1,
      ),
    ],
  );
}

class _Roster extends TeacherLearnerRosterController {
  @override
  Future<TeacherLearnerRosterState> build() async => TeacherLearnerRosterState(
    items: [
      TeacherLearnerEnrollment(
        id: 'enrollment-1',
        studentId: 'student-1',
        studentName: 'Ayesha',
        courseId: 'course-1',
        courseTitle: 'Kashmir Studies',
        enrolledAt: DateTime(2026, 10, 24),
        status: 'active',
      ),
    ],
  );
}

void main() {
  testWidgets(
    'live learner roster shows the enrolled student without mock metrics',
    (tester) async {
      AppConfig.isSupabaseEnabled = true;
      addTearDown(() => AppConfig.isSupabaseEnabled = false);
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teacherControllerProvider.overrideWith(_Teacher.new),
            teacherLearnerRosterProvider.overrideWith(_Roster.new),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              theme: AppTheme.lightTheme,
              home: const TeacherStudentsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ayesha'), findsOneWidget);
      expect(find.textContaining('Kashmir Studies'), findsWidgets);
      expect(find.text('Learner Analytics & Roster'), findsOneWidget);
      expect(find.textContaining('% Quiz'), findsNothing);
      expect(find.textContaining('private@example.com'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

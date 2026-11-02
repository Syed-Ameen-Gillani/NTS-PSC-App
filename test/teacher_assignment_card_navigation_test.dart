import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_theme.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/assignments/presentation/widgets/teacher_assignments_section.dart';

class _Assignments extends AssignmentsController {
  _Assignments(this.items);

  final List<AssignmentModel> items;

  @override
  FutureOr<AssignmentsState> build() => AssignmentsState(assignments: items);
}

void main() {
  for (final published in [false, true]) {
    testWidgets(
      '${published ? 'published' : 'draft'} assignment card opens the correct screen',
      (tester) async {
        final assignment = AssignmentModel(
          id: 'assignment-1',
          courseId: 'course-1',
          courseTitle: 'Course',
          title: published ? 'Published work' : 'Draft work',
          instructions: 'Instructions',
          dueAt: DateTime(2027),
          isPublished: published,
        );
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) =>
                  const Scaffold(body: TeacherAssignmentsSection()),
            ),
            GoRoute(
              path: AppRoute.teacherCreateAssignment.path,
              name: AppRoute.teacherCreateAssignment.name,
              builder: (_, state) => Scaffold(
                body: Text(
                  state.extra == assignment
                      ? 'Edit draft opened'
                      : 'Wrong draft',
                ),
              ),
            ),
            GoRoute(
              path: AppRoute.teacherReviewAssignment.path,
              name: AppRoute.teacherReviewAssignment.name,
              builder: (_, state) => Scaffold(
                body: Text(
                  state.extra == assignment ? 'Review opened' : 'Wrong review',
                ),
              ),
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              assignmentsControllerProvider.overrideWith(
                () => _Assignments([assignment]),
              ),
            ],
            child: ScreenUtilInit(
              designSize: const Size(375, 812),
              builder: (_, _) => MaterialApp.router(
                theme: AppTheme.lightTheme,
                routerConfig: router,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(assignment.title));
        await tester.pumpAndSettle();
        expect(
          find.text(published ? 'Review opened' : 'Edit draft opened'),
          findsOneWidget,
        );
        router.dispose();
      },
    );
  }
}

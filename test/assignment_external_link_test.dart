import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/assignments/presentation/pages/student_assignment_screen.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';

class _StudentAuthController extends AuthController {
  @override
  FutureOr<AuthState> build() => AuthState(selectedRole: UserRole.student);
}

class _EmptyAssignmentsController extends AssignmentsController {
  @override
  FutureOr<AssignmentsState> build() => const AssignmentsState();
}

Widget _app(String? externalUrl) => ProviderScope(
  overrides: [
    authControllerProvider.overrideWith(_StudentAuthController.new),
    assignmentsControllerProvider.overrideWith(_EmptyAssignmentsController.new),
  ],
  child: ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, __) => MaterialApp(
      home: StudentAssignmentScreen(
        assignment: AssignmentModel(
          id: 'assignment-1',
          courseId: 'course-1',
          courseTitle: 'Pakistan Affairs',
          title: 'Case study',
          instructions: 'Review the source material.',
          externalUrl: externalUrl,
          dueAt: DateTime.now().add(const Duration(days: 2)),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('student sees the saved assignment link', (tester) async {
    await tester.pumpWidget(_app('https://example.com/task'));
    await tester.pumpAndSettle();

    expect(find.text('Open assignment link'), findsOneWidget);
  });

  testWidgets('student sees no link action when none was added', (
    tester,
  ) async {
    await tester.pumpWidget(_app(null));
    await tester.pumpAndSettle();

    expect(find.text('Open assignment link'), findsNothing);
  });
}

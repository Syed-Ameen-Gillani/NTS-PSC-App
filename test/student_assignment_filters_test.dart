import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/assignments/presentation/widgets/student_assignments_section.dart';

class _FixtureAssignmentsController extends AssignmentsController {
  @override
  FutureOr<AssignmentsState> build() {
    final titles = [
      'New essay',
      'Pending essay',
      'Approved essay',
      'Rejected essay',
      'Teacher draft',
    ];
    final assignments = [
      for (var i = 0; i < titles.length; i++)
        AssignmentModel(
          id: 'assignment_$i',
          courseId: 'course_1',
          courseTitle: 'Pakistan Affairs',
          title: titles[i],
          instructions: 'Write an answer.',
          dueAt: DateTime.now().add(const Duration(days: 7)),
          isPublished: i != 4,
        ),
    ];
    final statuses = [
      AssignmentReviewStatus.pending,
      AssignmentReviewStatus.approved,
      AssignmentReviewStatus.disapproved,
    ];
    return AssignmentsState(
      assignments: assignments,
      submissions: [
        for (var i = 0; i < statuses.length; i++)
          AssignmentSubmissionModel(
            id: 'submission_$i',
            assignmentId: 'assignment_${i + 1}',
            studentId: 'student_1',
            studentName: 'Student',
            response: 'Answer',
            submittedAt: DateTime.now(),
            status: statuses[i],
          ),
      ],
    );
  }
}

void main() {
  testWidgets('student assignments filter by review state and search title', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assignmentsControllerProvider.overrideWith(
            _FixtureAssignmentsController.new,
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: StudentAssignmentsSection()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weekly Goal'), findsNothing);
    expect(find.text('Teacher draft'), findsNothing);
    expect(find.text('New essay'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Needs action'),
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Needs action'));
    await tester.pumpAndSettle();
    expect(find.text('Rejected essay'), findsOneWidget);
    expect(find.text('Pending essay'), findsNothing);
    expect(find.text('New essay'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('All'),
      -150,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('All'));
    await tester.tap(find.byTooltip('Search assignments'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'approved');
    await tester.pumpAndSettle();
    expect(find.text('Approved essay'), findsOneWidget);
    expect(find.text('Rejected essay'), findsNothing);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/features/assignments/data/mock_assignment_repository.dart';
import 'package:nts_psc_app/features/assignments/domain/assignment_link.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  test('assignment link is optional and must be HTTPS', () async {
    expect(assignmentLinkError(null), isNull);
    expect(assignmentLinkError('  '), isNull);
    expect(assignmentLinkError('https://example.com/task'), isNull);
    expect(assignmentLinkError('javascript:alert(1)'), isNotNull);
    expect(assignmentLinkError('http://example.com'), isNotNull);
    expect(assignmentLinkError('https://user@example.com'), isNotNull);

    final repository = MockAssignmentRepository();
    await expectLater(
      repository.createAssignment(
        courseId: 'c1',
        courseTitle: 'Course',
        title: 'Task',
        instructions: 'Complete it.',
        externalUrl: 'http://example.com',
        dueAt: DateTime.now().add(const Duration(days: 2)),
      ),
      throwsArgumentError,
    );
    final assignment = await repository.createAssignment(
      courseId: 'c1',
      courseTitle: 'Course',
      title: 'Task',
      instructions: 'Complete it.',
      externalUrl: ' https://example.com/task ',
      dueAt: DateTime.now().add(const Duration(days: 2)),
    );
    expect(assignment.externalUrl, 'https://example.com/task');
  });

  test(
    'assignment submission can be disapproved, revised, and approved',
    () async {
      final repository = MockAssignmentRepository();
      final assignment = await repository.createAssignment(
        courseId: 'c1',
        courseTitle: 'FPSC Inspector Customs',
        title: 'Case analysis',
        instructions: 'Explain the customs clearance process.',
        dueAt: DateTime.now().add(const Duration(days: 2)),
      );
      expect((await repository.getAssignments()).first.id, assignment.id);

      final first = await repository.submit(
        assignmentId: assignment.id,
        studentId: 'student_1',
        studentName: 'Ahmed Ali',
        response: '',
        attachments: const [
          AssignmentAttachmentModel(
            name: 'customs-analysis.pdf',
            sizeBytes: 2048,
            path: 'customs-analysis.pdf',
          ),
        ],
      );
      expect(first.status, AssignmentReviewStatus.pending);
      expect(first.attachments.single.name, 'customs-analysis.pdf');
      await expectLater(
        repository.submit(
          assignmentId: assignment.id,
          studentId: 'student_1',
          studentName: 'Ahmed Ali',
          response: 'Duplicate answer',
        ),
        throwsStateError,
      );
      await expectLater(
        repository.review(
          submissionId: first.id,
          decision: AssignmentReviewStatus.disapproved,
          feedback: '',
        ),
        throwsArgumentError,
      );

      final disapproved = await repository.review(
        submissionId: first.id,
        decision: AssignmentReviewStatus.disapproved,
        feedback: 'Add the relevant Act sections.',
      );
      expect(disapproved.status, AssignmentReviewStatus.disapproved);
      final revised = await repository.submit(
        assignmentId: assignment.id,
        studentId: 'student_1',
        studentName: 'Ahmed Ali',
        response: 'Revised answer with Act sections',
      );
      expect(revised.id, first.id);
      expect(revised.status, AssignmentReviewStatus.pending);
      expect(revised.feedback, isEmpty);
      final approved = await repository.review(
        submissionId: revised.id,
        decision: AssignmentReviewStatus.approved,
        feedback: '',
      );
      expect(approved.status, AssignmentReviewStatus.approved);
      await expectLater(
        repository.submit(
          assignmentId: assignment.id,
          studentId: 'student_1',
          studentName: 'Ahmed Ali',
          response: 'Another answer',
        ),
        throwsStateError,
      );
    },
  );

  test('assignment controller enforces teacher and student roles', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    await container.read(assignmentsControllerProvider.future);
    final controller = container.read(assignmentsControllerProvider.notifier);
    final dueAt = DateTime.now().add(const Duration(days: 2));

    await expectLater(
      controller.createAssignment(
        courseId: 'c1',
        courseTitle: 'FPSC Inspector Customs',
        title: 'Case analysis',
        instructions: 'Write your analysis.',
        dueAt: dueAt,
      ),
      throwsStateError,
    );
    container
        .read(authControllerProvider.notifier)
        .selectRole(UserRole.teacher);
    final assignment = await controller.createAssignment(
      courseId: 'c1',
      courseTitle: 'FPSC Inspector Customs',
      title: 'Case analysis',
      instructions: 'Write your analysis.',
      dueAt: dueAt,
    );
    await expectLater(
      controller.submit(assignmentId: assignment.id, response: 'Answer'),
      throwsStateError,
    );
    container
        .read(authControllerProvider.notifier)
        .selectRole(UserRole.student);
    final submission = await controller.submit(
      assignmentId: assignment.id,
      response: 'Student answer',
    );
    expect(
      container
          .read(assignmentsControllerProvider)
          .value!
          .submissionFor(assignment.id, 'student_1')
          ?.status,
      AssignmentReviewStatus.pending,
    );
    await expectLater(
      controller.review(
        submissionId: submission.id,
        decision: AssignmentReviewStatus.approved,
      ),
      throwsStateError,
    );
    container
        .read(authControllerProvider.notifier)
        .selectRole(UserRole.teacher);
    await controller.review(
      submissionId: submission.id,
      decision: AssignmentReviewStatus.approved,
    );
    expect(
      container
          .read(assignmentsControllerProvider)
          .value!
          .submissionFor(assignment.id, 'student_1')
          ?.status,
      AssignmentReviewStatus.approved,
    );
  });

  test('teacher can edit a draft and publish it before its due date', () async {
    final repository = MockAssignmentRepository();
    final draft = (await repository.getAssignments()).firstWhere(
      (assignment) => !assignment.isPublished,
    );
    final updated = await repository.updateAssignment(
      assignmentId: draft.id,
      title: 'Revised assignment',
      instructions: 'Write a longer answer.',
      externalUrl: 'https://example.com/assignment',
      dueAt: DateTime.now().add(const Duration(days: 3)),
    );
    expect(updated.title, 'Revised assignment');
    expect(updated.isPublished, isFalse);
    expect(updated.externalUrl, 'https://example.com/assignment');

    final published = await repository.publishAssignment(updated.id);
    expect(published.isPublished, isTrue);
    expect(published.externalUrl, updated.externalUrl);
    await expectLater(
      repository.updateAssignment(
        assignmentId: published.id,
        title: 'Changed after publication',
        instructions: published.instructions,
        dueAt: published.dueAt,
      ),
      throwsStateError,
    );
  });
}

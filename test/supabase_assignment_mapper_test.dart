import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';
import 'package:nts_psc_app/features/assignments/data/supabase_assignment_repository.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';

void main() {
  test('maps assignment publication and course title', () {
    final assignment = SupabaseAssignmentRepository.mapAssignmentRow({
      'id': 'assignment-1',
      'course_id': 'course-1',
      'title': 'Essay',
      'instructions': 'Explain the topic',
      'external_url': 'https://example.com/task',
      'due_at': '2026-10-31T18:59:00Z',
      'status': 'draft',
      'courses': {'title': 'Pakistan Affairs'},
    });

    expect(assignment.courseTitle, 'Pakistan Affairs');
    expect(assignment.externalUrl, 'https://example.com/task');
    expect(assignment.isPublished, isFalse);
    expect(
      assignment.dueAt.toUtc().toIso8601String(),
      '2026-10-31T18:59:00.000Z',
    );
  });

  test('maps teacher brief files without treating them as submissions', () {
    const brief = AssignmentAttachmentModel(
      name: 'Rubric.pdf',
      sizeBytes: 1024,
      path: 'briefs/teacher/assignment/rubric.pdf',
    );
    final assignment = SupabaseAssignmentRepository.mapAssignmentRow(
      {
        'id': 'assignment-1',
        'course_id': 'course-1',
        'title': 'Essay',
        'instructions': 'Explain the topic',
        'due_at': '2026-10-31T18:59:00Z',
        'status': 'published',
        'courses': {'title': 'Pakistan Affairs'},
      },
      attachments: [brief],
    );

    expect(assignment.isPublished, isTrue);
    expect(assignment.externalUrl, isNull);
    expect(assignment.attachments.single.path, brief.path);
  });

  test('validates teacher brief type, size, and five-file limit', () {
    final valid = AssignmentAttachmentModel(
      name: 'Rubric.pdf',
      sizeBytes: 3,
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    expect(
      () => SupabaseAssignmentRepository.validateBriefs([valid]),
      returnsNormally,
    );
    expect(
      () => SupabaseAssignmentRepository.validateBriefs([
        AssignmentAttachmentModel(
          name: 'Example.mp4',
          sizeBytes: 3,
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      ]),
      returnsNormally,
    );
    expect(
      () => SupabaseAssignmentRepository.validateBriefs(List.filled(6, valid)),
      throwsArgumentError,
    );
    expect(
      () => SupabaseAssignmentRepository.validateBriefs([
        AssignmentAttachmentModel(
          name: 'Archive.zip',
          sizeBytes: 3,
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      ]),
      throwsArgumentError,
    );
    expect(
      () => SupabaseAssignmentRepository.validateBriefs([
        const AssignmentAttachmentModel(
          name: 'Rubric.pdf',
          sizeBytes: 25 * 1024 * 1024 + 1,
          path: 'briefs/teacher/assignment/rubric.pdf',
        ),
      ]),
      throwsArgumentError,
    );
  });

  test('maps reviewed submission without inventing attachment rows', () {
    final submission = SupabaseAssignmentRepository.mapSubmissionRow(
      {
        'id': 'submission-1',
        'assignment_id': 'assignment-1',
        'student_id': 'student-1',
        'status': 'disapproved',
        'submitted_at': '2026-10-10T12:00:00Z',
        'feedback': 'Please cite sources',
      },
      response: 'First answer',
      studentName: 'Student',
    );

    expect(submission.status, AssignmentReviewStatus.disapproved);
    expect(submission.feedback, 'Please cite sources');
    expect(submission.response, 'First answer');
    expect(submission.attachments, isEmpty);
  });
}

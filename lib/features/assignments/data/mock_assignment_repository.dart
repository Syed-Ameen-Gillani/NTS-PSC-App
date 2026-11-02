import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/domain/assignment_link.dart';
import 'package:nts_psc_app/features/assignments/domain/repositories/assignment_repository.dart';

class MockAssignmentRepository implements AssignmentRepository {
  @override
  Future<String> getAttachmentUrl(String path) async => path;
  final List<AssignmentModel> _assignments = [
    AssignmentModel(
      id: 'assignment_1',
      courseId: 'c1',
      courseTitle: 'FPSC Inspector Customs & Intelligence Officer',
      title: 'Customs Act case study',
      instructions:
          'Explain the difference between home consumption and warehousing clearance. Include the relevant Customs Act sections and one practical example.',
      dueAt: DateTime.now().add(const Duration(days: 7)),
      isPublished: true,
    ),
    AssignmentModel(
      id: 'assignment_2',
      courseId: 'c2',
      courseTitle: 'AJK PSC General Recruitment Masterclass',
      title: 'AJK constitutional framework',
      instructions:
          'Summarize the main institutions established by the AJK Interim Constitution Act 1974 and explain their responsibilities.',
      dueAt: DateTime.now().add(const Duration(days: 10)),
      isPublished: false,
    ),
  ];

  final List<AssignmentSubmissionModel> _submissions = [
    AssignmentSubmissionModel(
      id: 'submission_1',
      assignmentId: 'assignment_1',
      studentId: 'student_2',
      studentName: 'Ayesha Siddiqa',
      response:
          'Home consumption releases imported goods after assessment and duty payment. Warehousing allows goods to be stored under customs control before duties are paid.',
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  int _nextAssignmentId = 3;
  int _nextSubmissionId = 2;

  @override
  Future<List<AssignmentModel>> getAssignments() async =>
      List.unmodifiable(_assignments);

  @override
  Future<List<AssignmentSubmissionModel>> getSubmissions() async =>
      List.unmodifiable(_submissions);

  @override
  Future<AssignmentModel> createAssignment({
    required String courseId,
    required String courseTitle,
    required String title,
    required String instructions,
    String? externalUrl,
    required DateTime dueAt,
    List<AssignmentAttachmentModel> attachments = const [],
  }) async {
    if (courseId.isEmpty ||
        title.trim().isEmpty ||
        instructions.trim().isEmpty) {
      throw ArgumentError('Course, title, and instructions are required');
    }
    if (!dueAt.isAfter(DateTime.now())) {
      throw ArgumentError('Due date must be in the future');
    }
    final linkError = assignmentLinkError(externalUrl);
    if (linkError != null) throw ArgumentError(linkError);
    final assignment = AssignmentModel(
      id: 'assignment_${_nextAssignmentId++}',
      courseId: courseId,
      courseTitle: courseTitle,
      title: title.trim(),
      instructions: instructions.trim(),
      externalUrl: externalUrl?.trim().isEmpty ?? true
          ? null
          : externalUrl!.trim(),
      dueAt: dueAt,
      attachments: attachments,
    );
    _assignments.insert(0, assignment);
    return assignment;
  }

  @override
  Future<AssignmentModel> updateAssignment({
    required String assignmentId,
    required String title,
    required String instructions,
    String? externalUrl,
    required DateTime dueAt,
    List<AssignmentAttachmentModel> attachments = const [],
  }) async {
    final index = _assignments.indexWhere((item) => item.id == assignmentId);
    if (index < 0 || _assignments[index].isPublished) {
      throw StateError('Draft assignment not found');
    }
    final previous = _assignments[index];
    final linkError = assignmentLinkError(externalUrl);
    if (linkError != null) throw ArgumentError(linkError);
    final updated = AssignmentModel(
      id: previous.id,
      courseId: previous.courseId,
      courseTitle: previous.courseTitle,
      title: title.trim(),
      instructions: instructions.trim(),
      externalUrl: externalUrl?.trim().isEmpty ?? true
          ? null
          : externalUrl!.trim(),
      dueAt: dueAt,
      isPublished: false,
      attachments: attachments.isNotEmpty ? attachments : previous.attachments,
    );
    _assignments[index] = updated;
    return updated;
  }

  @override
  Future<AssignmentModel> publishAssignment(String assignmentId) async {
    final index = _assignments.indexWhere((item) => item.id == assignmentId);
    if (index < 0 || _assignments[index].isPublished) {
      throw StateError('Draft assignment not found');
    }
    final previous = _assignments[index];
    if (!previous.dueAt.isAfter(DateTime.now())) {
      throw StateError('Due date must be in the future');
    }
    final published = AssignmentModel(
      id: previous.id,
      courseId: previous.courseId,
      courseTitle: previous.courseTitle,
      title: previous.title,
      instructions: previous.instructions,
      externalUrl: previous.externalUrl,
      dueAt: previous.dueAt,
      isPublished: true,
    );
    _assignments[index] = published;
    return published;
  }

  @override
  Future<AssignmentSubmissionModel> submit({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String response,
    List<AssignmentAttachmentModel> attachments = const [],
  }) async {
    final assignment = _assignments.firstWhere(
      (item) => item.id == assignmentId,
      orElse: () => throw StateError('Assignment not found'),
    );
    if (DateTime.now().isAfter(assignment.dueAt)) {
      throw StateError('This assignment is closed');
    }
    if (response.trim().isEmpty && attachments.isEmpty) {
      throw ArgumentError('A response or attachment is required');
    }
    final index = _submissions.indexWhere(
      (item) =>
          item.assignmentId == assignmentId && item.studentId == studentId,
    );
    if (index >= 0 &&
        _submissions[index].status != AssignmentReviewStatus.disapproved) {
      throw StateError('This assignment has already been submitted');
    }
    final submitted = index >= 0
        ? _submissions[index].copyWith(
            response: response.trim(),
            submittedAt: DateTime.now(),
            status: AssignmentReviewStatus.pending,
            feedback: '',
            attachments: List.unmodifiable(attachments),
          )
        : AssignmentSubmissionModel(
            id: 'submission_${_nextSubmissionId++}',
            assignmentId: assignmentId,
            studentId: studentId,
            studentName: studentName,
            response: response.trim(),
            submittedAt: DateTime.now(),
            attachments: List.unmodifiable(attachments),
          );
    if (index >= 0) {
      _submissions[index] = submitted;
    } else {
      _submissions.insert(0, submitted);
    }
    return submitted;
  }

  @override
  Future<AssignmentSubmissionModel> review({
    required String submissionId,
    required AssignmentReviewStatus decision,
    required String feedback,
  }) async {
    final index = _submissions.indexWhere((item) => item.id == submissionId);
    if (index < 0 ||
        _submissions[index].status != AssignmentReviewStatus.pending) {
      throw StateError('Pending submission not found');
    }
    if (decision == AssignmentReviewStatus.pending ||
        (decision == AssignmentReviewStatus.disapproved &&
            feedback.trim().isEmpty)) {
      throw ArgumentError(
        'A decision and feedback for disapproval are required',
      );
    }
    final reviewed = _submissions[index].copyWith(
      status: decision,
      feedback: feedback.trim(),
    );
    _submissions[index] = reviewed;
    return reviewed;
  }
}

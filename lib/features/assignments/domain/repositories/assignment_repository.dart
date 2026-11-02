import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';

abstract class AssignmentRepository {
  Future<String> getAttachmentUrl(String path);
  Future<List<AssignmentModel>> getAssignments();
  Future<List<AssignmentSubmissionModel>> getSubmissions();
  Future<AssignmentModel> createAssignment({
    required String courseId,
    required String courseTitle,
    required String title,
    required String instructions,
    String? externalUrl,
    required DateTime dueAt,
    List<AssignmentAttachmentModel> attachments = const [],
  });
  Future<AssignmentModel> updateAssignment({
    required String assignmentId,
    required String title,
    required String instructions,
    String? externalUrl,
    required DateTime dueAt,
    List<AssignmentAttachmentModel> attachments = const [],
  });
  Future<AssignmentModel> publishAssignment(String assignmentId);
  Future<AssignmentSubmissionModel> submit({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String response,
    List<AssignmentAttachmentModel> attachments = const [],
  });
  Future<AssignmentSubmissionModel> review({
    required String submissionId,
    required AssignmentReviewStatus decision,
    required String feedback,
  });
}

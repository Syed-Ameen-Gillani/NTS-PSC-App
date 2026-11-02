import 'dart:typed_data';

enum AssignmentReviewStatus { pending, approved, disapproved }

class AssignmentAttachmentModel {
  final String name;
  final int sizeBytes;
  final String? path;
  final Uint8List? bytes;

  const AssignmentAttachmentModel({
    required this.name,
    required this.sizeBytes,
    this.path,
    this.bytes,
  });
}

class AssignmentRevisionModel {
  final int number;
  final String response;
  final DateTime submittedAt;
  final List<AssignmentAttachmentModel> attachments;

  const AssignmentRevisionModel({
    required this.number,
    required this.response,
    required this.submittedAt,
    this.attachments = const [],
  });
}

class AssignmentModel {
  final String id;
  final String courseId;
  final String courseTitle;
  final String title;
  final String instructions;
  final String? externalUrl;
  final DateTime dueAt;
  final bool isPublished;
  final List<AssignmentAttachmentModel> attachments;

  const AssignmentModel({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.title,
    required this.instructions,
    this.externalUrl,
    required this.dueAt,
    this.isPublished = true,
    this.attachments = const [],
  });
}

class AssignmentSubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String response;
  final DateTime submittedAt;
  final AssignmentReviewStatus status;
  final String feedback;
  final List<AssignmentAttachmentModel>? _attachments;
  final List<AssignmentRevisionModel> revisions;

  List<AssignmentAttachmentModel> get attachments => _attachments ?? const [];

  const AssignmentSubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.response,
    required this.submittedAt,
    this.status = AssignmentReviewStatus.pending,
    this.feedback = '',
    List<AssignmentAttachmentModel>? attachments,
    this.revisions = const [],
  }) : _attachments = attachments ?? const [];

  AssignmentSubmissionModel copyWith({
    String? response,
    DateTime? submittedAt,
    AssignmentReviewStatus? status,
    String? feedback,
    List<AssignmentAttachmentModel>? attachments,
    List<AssignmentRevisionModel>? revisions,
  }) {
    return AssignmentSubmissionModel(
      id: id,
      assignmentId: assignmentId,
      studentId: studentId,
      studentName: studentName,
      response: response ?? this.response,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      feedback: feedback ?? this.feedback,
      attachments: attachments ?? this.attachments,
      revisions: revisions ?? this.revisions,
    );
  }
}

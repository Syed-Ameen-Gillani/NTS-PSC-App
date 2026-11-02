import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/assignments/data/assignment_repository_provider.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_learner_roster_controller.dart';

class AssignmentsState {
  final List<AssignmentModel> assignments;
  final List<AssignmentSubmissionModel> submissions;

  const AssignmentsState({
    this.assignments = const [],
    this.submissions = const [],
  });

  AssignmentSubmissionModel? submissionFor(
    String assignmentId,
    String studentId,
  ) {
    for (final submission in submissions) {
      if (submission.assignmentId == assignmentId &&
          submission.studentId == studentId) {
        return submission;
      }
    }
    return null;
  }

  List<AssignmentSubmissionModel> submissionsFor(String assignmentId) =>
      submissions.where((item) => item.assignmentId == assignmentId).toList();
}

class AssignmentsController extends AsyncNotifier<AssignmentsState> {
  @override
  FutureOr<AssignmentsState> build() async {
    if (AppConfig.isSupabaseEnabled) {
      final auth = await ref.watch(authControllerProvider.future);
      if (auth.user == null) return const AssignmentsState();
    }
    final repository = ref.read(assignmentRepositoryProvider);
    final assignmentsRequest = repository.getAssignments();
    final submissionsRequest = repository.getSubmissions();
    return AssignmentsState(
      assignments: await assignmentsRequest,
      submissions: await submissionsRequest,
    );
  }

  Future<void> _requireRole(UserRole role) async {
    final auth = await ref.read(authControllerProvider.future);
    if ((AppConfig.isSupabaseEnabled ? auth.user?.role : auth.selectedRole) !=
        role) {
      throw StateError('${role.label} access required');
    }
  }

  void _replaceAssignment(AssignmentModel updated) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      AssignmentsState(
        assignments: [
          for (final item in current.assignments)
            item.id == updated.id ? updated : item,
        ],
        submissions: current.submissions,
      ),
    );
  }

  Future<void> updateAssignment({
    required String assignmentId,
    required String title,
    required String instructions,
    String? externalUrl,
    required DateTime dueAt,
    List<AssignmentAttachmentModel> attachments = const [],
  }) async {
    await _requireRole(UserRole.teacher);
    final updated = await ref
        .read(assignmentRepositoryProvider)
        .updateAssignment(
          assignmentId: assignmentId,
          title: title,
          instructions: instructions,
          externalUrl: externalUrl,
          dueAt: dueAt,
          attachments: attachments,
        );
    _replaceAssignment(updated);
  }

  Future<void> publishAssignment(String assignmentId) async {
    await _requireRole(UserRole.teacher);
    final updated = await ref
        .read(assignmentRepositoryProvider)
        .publishAssignment(assignmentId);
    _replaceAssignment(updated);
  }

  Future<AssignmentModel> createAssignment({
    required String courseId,
    required String courseTitle,
    required String title,
    required String instructions,
    String? externalUrl,
    required DateTime dueAt,
    List<AssignmentAttachmentModel> attachments = const [],
  }) async {
    await _requireRole(UserRole.teacher);
    final created = await ref
        .read(assignmentRepositoryProvider)
        .createAssignment(
          courseId: courseId,
          courseTitle: courseTitle,
          title: title,
          instructions: instructions,
          externalUrl: externalUrl,
          dueAt: dueAt,
          attachments: attachments,
        );
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        AssignmentsState(
          assignments: [created, ...current.assignments],
          submissions: current.submissions,
        ),
      );
    }
    return created;
  }

  Future<AssignmentSubmissionModel> submit({
    required String assignmentId,
    required String response,
    List<AssignmentAttachmentModel> attachments = const [],
  }) async {
    await _requireRole(UserRole.student);
    final auth = await ref.read(authControllerProvider.future);
    final studentId =
        auth.user?.id ??
        (AppConfig.isSupabaseEnabled
            ? (throw StateError('Sign in to submit an assignment.'))
            : 'student_1');
    final submitted = await ref
        .read(assignmentRepositoryProvider)
        .submit(
          assignmentId: assignmentId,
          studentId: studentId,
          studentName:
              auth.user?.name ??
              (AppConfig.isSupabaseEnabled ? 'You' : 'Ahmed Ali'),
          response: response,
          attachments: attachments,
        );
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        AssignmentsState(
          assignments: current.assignments,
          submissions: [
            submitted,
            ...current.submissions.where((item) => item.id != submitted.id),
          ],
        ),
      );
    }
    return submitted;
  }

  Future<AssignmentSubmissionModel> review({
    required String submissionId,
    required AssignmentReviewStatus decision,
    String feedback = '',
  }) async {
    await _requireRole(UserRole.teacher);
    final reviewed = await ref
        .read(assignmentRepositoryProvider)
        .review(
          submissionId: submissionId,
          decision: decision,
          feedback: feedback,
        );
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        AssignmentsState(
          assignments: current.assignments,
          submissions: [
            for (final item in current.submissions)
              item.id == reviewed.id ? reviewed : item,
          ],
        ),
      );
    }
    ref.invalidate(teacherLearnerRosterProvider);
    ref.invalidate(teacherControllerProvider);
    return reviewed;
  }
}

final assignmentsControllerProvider =
    AsyncNotifierProvider<AssignmentsController, AssignmentsState>(
      AssignmentsController.new,
    );

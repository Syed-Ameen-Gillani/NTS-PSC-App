import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/presentation/widgets/assessment_feedback_banner.dart';

class AssignmentPerformanceFeedback extends ConsumerWidget {
  const AssignmentPerformanceFeedback({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentId =
        ref.watch(authControllerProvider).value?.user?.id ??
        (AppConfig.isSupabaseEnabled ? '' : 'student_1');
    return ref
        .watch(assignmentsControllerProvider)
        .when(
          loading: () => const AssessmentFeedbackBanner(
            icon: Icons.assignment_outlined,
            title: 'Loading your feedback',
            message: 'Reviewing your latest assignment activity…',
          ),
          error: (_, __) => const AssessmentFeedbackBanner(
            icon: Icons.assignment_outlined,
            title: 'Feedback unavailable',
            message: 'Your assignments are still available below.',
          ),
          data: (state) {
            final published = state.assignments
                .where((assignment) => assignment.isPublished)
                .toList();
            final submissions = {
              for (final assignment in published)
                assignment.id: state.submissionFor(assignment.id, studentId),
            };
            final rejected = published.where(
              (assignment) =>
                  submissions[assignment.id]?.status ==
                  AssignmentReviewStatus.disapproved,
            );
            final pending = submissions.values.where(
              (submission) =>
                  submission?.status == AssignmentReviewStatus.pending,
            );
            final approved = submissions.values.where(
              (submission) =>
                  submission?.status == AssignmentReviewStatus.approved,
            );
            final recommended = rejected.firstOrNull;
            final submitted =
                approved.length + pending.length + rejected.length;

            return AssessmentFeedbackBanner(
              icon: recommended == null
                  ? Icons.assignment_turned_in_outlined
                  : Icons.rate_review_outlined,
              title: submitted == 0
                  ? 'Your assignment feedback'
                  : '${approved.length} approved · ${pending.length} awaiting review',
              message: recommended == null
                  ? submitted == 0
                        ? 'Submit an assignment to receive instructor feedback.'
                        : 'Your submitted work is progressing well.'
                  : 'Revise ${recommended.title} using your instructor feedback.',
              onTap: recommended == null
                  ? null
                  : () => context.pushNamed(
                      AppRoute.studentAssignment.name,
                      extra: recommended,
                    ),
            );
          },
        );
  }
}

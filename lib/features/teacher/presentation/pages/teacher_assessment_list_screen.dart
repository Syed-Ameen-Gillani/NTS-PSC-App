import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/assignments/presentation/widgets/teacher_assignments_section.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_quiz_studio_screen.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';

class TeacherAssessmentListScreen extends ConsumerWidget {
  const TeacherAssessmentListScreen({
    super.key,
    required this.kind,
    required this.published,
    this.targetScope,
  });

  final String kind;
  final bool published;
  final CurriculumScope? targetScope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isQuiz = kind == 'quiz';
    final status = published ? 'Published' : 'Draft';
    final title = '$status ${isQuiz ? 'Quizzes' : 'Assignments'}';
    return AppScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: Text(
          title,
          style: AppTextStyles.interBold24.copyWith(fontSize: 20.sp),
        ),
      ),
      body: SafeArea(
        child: isQuiz
            ? ref
                  .watch(teacherControllerProvider)
                  .when(
                    data: (state) {
                      final items = state.quizzes
                          .where((quiz) => (quiz.courseId != null) == published)
                          .toList();
                      return _AssessmentList(
                        count: items.length,
                        children: [
                          for (final quiz in items)
                            TeacherQuizListItem(
                              quiz: quiz,
                              targetScope: targetScope,
                            ),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) =>
                        const Center(child: Text('Could not load quizzes.')),
                  )
            : ref
                  .watch(assignmentsControllerProvider)
                  .when(
                    data: (state) {
                      final items = state.assignments
                          .where((item) => item.isPublished == published)
                          .toList();
                      return _AssessmentList(
                        count: items.length,
                        children: [
                          for (final assignment in items)
                            TeacherAssignmentListItem(
                              assignment: assignment,
                              state: state,
                              targetScope: targetScope,
                            ),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const Center(
                      child: Text('Could not load assignments.'),
                    ),
                  ),
      ),
    );
  }
}

class _AssessmentList extends StatelessWidget {
  const _AssessmentList({required this.count, required this.children});

  final int count;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const Center(child: Text('Nothing here yet.'));
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 32.h),
      itemCount: children.length,
      separatorBuilder: (_, _) => SizedBox(height: 10.h),
      itemBuilder: (_, index) => children[index],
    );
  }
}

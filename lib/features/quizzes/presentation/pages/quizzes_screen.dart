import 'package:nts_psc_app/presentation/widgets/student_tab_header.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/quizzes/presentation/controllers/quizzes_controller.dart';
import 'package:nts_psc_app/presentation/widgets/category_filter_chips.dart';
import 'package:nts_psc_app/presentation/widgets/quiz_card.dart';
import 'package:nts_psc_app/features/assignments/presentation/widgets/student_assignments_section.dart';
import 'package:nts_psc_app/presentation/widgets/assessment_type_tabs.dart';
import 'package:nts_psc_app/features/quizzes/presentation/widgets/quiz_performance_feedback.dart';
import 'package:nts_psc_app/features/assignments/presentation/widgets/assignment_performance_feedback.dart';

class QuizzesScreen extends ConsumerWidget {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final tabs = DefaultTabController.of(context);
          final header = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StudentTabHeader(title: 'Assessments'),
              SizedBox(height: 16.h),
              const AssessmentTypeTabs(),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: AnimatedBuilder(
                  animation: tabs,
                  builder: (context, _) => tabs.index == 0
                      ? Consumer(
                          builder: (context, ref, _) => ref
                              .watch(quizzesControllerProvider)
                              .when(
                                data: (state) => QuizPerformanceFeedback(
                                  quizzes: state.courseQuizzes,
                                ),
                                loading: () =>
                                    const AssessmentFeedbackLoading(),
                                error: (_, __) =>
                                    const AssessmentFeedbackUnavailable(),
                              ),
                        )
                      : const AssignmentPerformanceFeedback(),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          );
          final compact =
              MediaQuery.orientationOf(context) == Orientation.landscape;
          return AppScaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  if (compact)
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.42,
                      child: SingleChildScrollView(child: header),
                    )
                  else
                    header,
                  Expanded(
                    child: TabBarView(
                      children: [
                        const _QuizzesContent(),
                        StudentAssignmentsSection(
                          showHeader: false,
                          fillAvailableHeight: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuizzesContent extends ConsumerWidget {
  const _QuizzesContent();

  static final _filterProvider = StateProvider.autoDispose<int>((ref) => 0);

  bool _hasPassed(QuizModel quiz) {
    final parts = quiz.score?.split('/');
    if (parts == null || parts.length != 2) return false;
    final correct = int.tryParse(parts.first.trim());
    final total = int.tryParse(parts.last.trim());
    return correct != null &&
        total != null &&
        total > 0 &&
        correct * 100 / total >= quiz.passingScore;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesStateAsync = ref.watch(quizzesControllerProvider);

    return AppScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: quizzesStateAsync.when(
        data: (state) {
          final selectedFilter = ref.watch(_filterProvider);

          final visibleQuizzes = state.courseQuizzes
              .where(
                (quiz) => switch (selectedFilter) {
                  1 => !_hasPassed(quiz),
                  2 => _hasPassed(quiz),
                  _ => true,
                },
              )
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryFilterChips(
                filters: const ['All', 'Needs action', 'Completed'],
                onSelected: (index) =>
                    ref.read(_filterProvider.notifier).state = index,
              ),
              SizedBox(height: 16.h),
              if (visibleQuizzes.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Text(
                        state.courseQuizzes.isEmpty
                            ? 'No quizzes available yet.'
                            : 'No quizzes match this filter.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.interRegular14.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.only(
                      left: 24.w,
                      right: 24.w,
                      bottom: 48.h,
                    ),
                    itemCount: visibleQuizzes.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 16.h),
                    itemBuilder: (context, index) =>
                        QuizCard(quiz: visibleQuizzes[index]),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Error loading quizzes')),
      ),
    );
  }
}

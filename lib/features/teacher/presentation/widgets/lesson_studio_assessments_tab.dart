part of '../pages/teacher_lesson_media_screen.dart';

extension _LessonStudioAssessmentsTab on _TeacherLessonMediaScreenState {
  Widget _buildAssessmentLinkCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.quiz_outlined,
              size: 40.w,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Link Assessments & Practice',
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 16.sp,
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Attach interactive quizzes or assignments to test student mastery.',
            textAlign: TextAlign.center,
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 13.sp,
              color: AppColors.grey500,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy.value ? null : () => _linkAssessment('quiz'),
                  icon: const Icon(Icons.quiz_outlined, size: 16),
                  label: const Text('Link Quiz'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy.value
                      ? null
                      : () => _linkAssessment('assignment'),
                  icon: const Icon(Icons.assignment_outlined, size: 16),
                  label: const Text('Assignment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentsTab(
    AsyncValue<List<PlacedCurriculumAssessment>> assessments,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          assessments.when(
            loading: () => Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30.h),
                child: const CircularProgressIndicator(),
              ),
            ),
            error: (_, _) => Column(
              children: [
                _buildAssessmentLinkCard(),
                const _AttachedEmptyState(
                  icon: Icons.error_outline,
                  title: 'Failed to load assessments',
                ),
              ],
            ),
            data: (items) {
              if (items.isEmpty) {
                return _buildAssessmentLinkCard();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAttachedHeader(
                    title: 'ATTACHED ASSESSMENTS',
                    onRetry: () => ref.invalidate(
                      curriculumVisibleAssessmentsProvider(_scope),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  ...items.map((placed) {
                    final item = placed.assessment;
                    final isQuiz = item.kind == 'quiz';
                    return Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              isQuiz
                                  ? Icons.quiz_outlined
                                  : Icons.assignment_outlined,
                              color: AppColors.primary,
                              size: 22.w,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: InkWell(
                              onTap: () => _openAssessment(item),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: AppTextStyles.interMedium16.copyWith(
                                      fontSize: 13.sp,
                                      color: AppColors.onBackground,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    '${isQuiz ? "Quiz" : "Assignment"} | ${placed.scope.targetLabel} | ${item.status.toUpperCase()}',
                                    style: AppTextStyles.interRegular14
                                        .copyWith(
                                          fontSize: 11.sp,
                                          color: AppColors.grey500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Unlink assessment',
                            icon: const Icon(
                              Icons.link_off,
                              size: 20,
                              color: AppColors.grey500,
                            ),
                            onPressed: () async {
                              final confirmed = await confirmAssessmentLinkChange(
                                context: context,
                                title: item.title,
                                target:
                                    'this ${placed.scope.targetLabel.toLowerCase()}',
                                unlink: true,
                              );
                              if (!confirmed || !mounted) return;
                              await _run(
                                () => ref
                                    .read(
                                      curriculumActionsProvider(
                                        placed.scope,
                                      ).notifier,
                                    )
                                    .unlink(item.id),
                              );
                              ref.invalidate(
                                curriculumVisibleAssessmentsProvider(_scope),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  Row(
                    children: [
                      Expanded(
                        child: _compactAddAction(
                          icon: Icons.add_circle_outline,
                          label: 'Link quiz',
                          filled: true,
                          onPressed: busy.value
                              ? null
                              : () => _linkAssessment('quiz'),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _compactAddAction(
                          icon: Icons.add_circle_outline,
                          label: 'Assignment',
                          onPressed: busy.value
                              ? null
                              : () => _linkAssessment('assignment'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

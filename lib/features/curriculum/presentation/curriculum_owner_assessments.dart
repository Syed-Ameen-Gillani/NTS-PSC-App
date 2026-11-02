part of 'curriculum_resources_screen.dart';

extension _OwnerAssessmentSection on _Content {
  Widget _buildOwnerAssessmentSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<CurriculumAssessment>> assessmentsAsync,
  ) => assessmentsAsync.when(
    loading: () => const SizedBox.shrink(),
    error: (_, _) => const SizedBox.shrink(),
    data: (items) {
      if (items.isEmpty) {
        // Conditional: do not show any section or placeholder when empty
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'ATTACHED ASSESSMENTS',
            icon: Icons.quiz_outlined,
            count: items.length,
          ),
          ...items.map((item) {
            final isQuiz = item.kind == 'quiz';
            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      isQuiz ? Icons.quiz_outlined : Icons.assignment_outlined,
                      color: AppColors.primary,
                      size: 20.w,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: InkWell(
                      onTap: () => _openAssessment(context, ref, item),
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
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 1.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  isQuiz ? 'Quiz' : 'Assignment',
                                  style: AppTextStyles.interBold24.copyWith(
                                    fontSize: 10.sp,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                '•  ${item.status.toUpperCase()}',
                                style: AppTextStyles.interRegular14.copyWith(
                                  fontSize: 11.sp,
                                  color: AppColors.grey500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (details.canManage)
                    IconButton(
                      tooltip: 'Unlink',
                      icon: const Icon(
                        Icons.link_off,
                        size: 20,
                        color: AppColors.grey500,
                      ),
                      onPressed: () async {
                        final confirmed = await confirmAssessmentLinkChange(
                          context: context,
                          title: item.title,
                          target: details.scope.targetLabel.toLowerCase(),
                          unlink: true,
                        );
                        if (!confirmed || !context.mounted) {
                          return;
                        }
                        await _run(
                          context,
                          () => ref
                              .read(
                                curriculumActionsProvider(
                                  details.scope,
                                ).notifier,
                              )
                              .unlink(item.id),
                        );
                      },
                    )
                  else
                    const Icon(Icons.chevron_right, color: AppColors.grey400),
                ],
              ),
            );
          }),
        ],
      );
    },
  );
}

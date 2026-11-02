import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_search_bar.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/assignments/presentation/widgets/assignment_status_badge.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/presentation/widgets/category_filter_chips.dart';

class StudentAssignmentsSection extends ConsumerWidget {
  const StudentAssignmentsSection({
    super.key,
    this.showHeader = true,
    this.fillAvailableHeight = false,
    this.searchQuery,
  });
  final bool showHeader;
  final bool fillAvailableHeight;
  final String? searchQuery;
  static const _filters = ['All', 'Needs action', 'In review', 'Completed'];
  static final _filterProvider = StateProvider.autoDispose<int>((ref) => 0);
  static final _showSearchProvider = StateProvider.autoDispose<bool>(
    (ref) => false,
  );
  static final _queryProvider = StateProvider.autoDispose<String>((ref) => '');

  bool _matchesStatus(AssignmentSubmissionModel? submission, int filter) =>
      switch (filter) {
        1 =>
          submission == null ||
              submission.status == AssignmentReviewStatus.disapproved,
        2 => submission?.status == AssignmentReviewStatus.pending,
        3 => submission?.status == AssignmentReviewStatus.approved,
        _ => true,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignments = ref.watch(assignmentsControllerProvider);
    final selectedFilter = ref.watch(_filterProvider);
    final showSearch = ref.watch(_showSearchProvider);
    final localQuery = ref.watch(_queryProvider);
    final search = (searchQuery ?? localQuery).trim().toLowerCase();
    final studentId =
        ref.watch(authControllerProvider).value?.user?.id ??
        (AppConfig.isSupabaseEnabled ? '' : 'student_1');
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Assignments',
                    style: AppTextStyles.interBold30.copyWith(
                      fontSize: 24.sp,
                      color: AppColors.onBackground,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: showSearch ? 'Close search' : 'Search assignments',
                  onPressed: () {
                    ref.read(_showSearchProvider.notifier).state = !showSearch;
                    if (showSearch) {
                      ref.read(_queryProvider.notifier).state = '';
                    }
                  },
                  icon: Icon(
                    showSearch ? Icons.close : Icons.search,
                    color: AppColors.onBackground,
                    size: 26.w,
                  ),
                ),
              ],
            ),
          if (showHeader && showSearch) ...[
            SizedBox(height: 12.h),
            CourseSearchField(
              autofocus: true,
              hintText: 'Search assignments or courses',
              onChanged: (value) =>
                  ref.read(_queryProvider.notifier).state = value,
            ),
          ],
          if (showHeader) SizedBox(height: 16.h),
          _MaybeExpanded(
            expanded: fillAvailableHeight,
            child: assignments.when(
              data: (state) {
                final published = state.assignments
                    .where((a) => a.isPublished)
                    .toList();
                final visible = published.where((assignment) {
                  final submission = state.submissionFor(
                    assignment.id,
                    studentId,
                  );
                  return _matchesStatus(submission, selectedFilter) &&
                      (search.isEmpty ||
                          assignment.title.toLowerCase().contains(search) ||
                          assignment.courseTitle.toLowerCase().contains(
                            search,
                          ));
                }).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryFilterChips(
                      filters: _filters,
                      includeHorizontalPadding: false,
                      onSelected: (index) =>
                          ref.read(_filterProvider.notifier).state = index,
                    ),
                    SizedBox(height: 16.h),
                    if (fillAvailableHeight)
                      Expanded(
                        child: visible.isEmpty
                            ? Center(
                                child: Text(
                                  published.isEmpty
                                      ? 'No assignments available yet.'
                                      : 'No assignments match your search or filter.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.interRegular14.copyWith(
                                    color: AppColors.grey600,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.only(bottom: 48.h),
                                itemCount: visible.length,
                                separatorBuilder: (context, index) =>
                                    SizedBox(height: 16.h),
                                itemBuilder: (context, index) =>
                                    _assignmentCard(
                                      context,
                                      state,
                                      visible[index],
                                      studentId,
                                    ),
                              ),
                      )
                    else if (visible.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: Text(
                          published.isEmpty
                              ? 'No assignments available'
                              : 'No assignments match this filter',
                          style: AppTextStyles.interRegular14.copyWith(
                            color: AppColors.grey500,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visible.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          return _assignmentCard(
                            context,
                            state,
                            visible[index],
                            studentId,
                          );
                        },
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const Text('Error loading assignments'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignmentCard(
    BuildContext context,
    AssignmentsState state,
    AssignmentModel assignment,
    String studentId,
  ) {
    final submission = state.submissionFor(assignment.id, studentId);
    return InkWell(
      onTap: () =>
          context.pushNamed(AppRoute.studentAssignment.name, extra: assignment),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.grey300, width: 1.w),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignment.courseTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.interMedium16.copyWith(
                fontSize: 12.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              assignment.title,
              style: AppTextStyles.interSemiBold16.copyWith(
                fontSize: 15.sp,
                color: AppColors.onBackground,
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 12.w,
              runSpacing: 8.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Due ${MaterialLocalizations.of(context).formatMediumDate(assignment.dueAt)}',
                  style: AppTextStyles.interRegular14.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.grey500,
                  ),
                ),
                AssignmentStatusBadge(status: submission?.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MaybeExpanded extends StatelessWidget {
  const _MaybeExpanded({required this.expanded, required this.child});

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      expanded ? Expanded(child: child) : child;
}

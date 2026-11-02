import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/domain/models/teacher_insights_models.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_learner_roster_controller.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:nts_psc_app/presentation/widgets/custom_search_bar.dart';

class TeacherLiveLearnersScreen extends ConsumerStatefulWidget {
  const TeacherLiveLearnersScreen({super.key, this.initialCourseTitle});

  final String? initialCourseTitle;

  @override
  ConsumerState<TeacherLiveLearnersScreen> createState() =>
      _TeacherLiveLearnersScreenState();
}

class _TeacherLiveLearnersScreenState
    extends ConsumerState<TeacherLiveLearnersScreen> {
  final _search = TextEditingController();
  Timer? _searchDelay;
  bool _initialCourseApplied = false;

  @override
  void dispose() {
    _searchDelay?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _searchChanged(String value, String? courseId) {
    _searchDelay?.cancel();
    _searchDelay = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref
          .read(teacherLearnerRosterProvider.notifier)
          .setFilters(query: value, courseId: courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(teacherControllerProvider).value?.courses ?? [];
    final roster = ref.watch(teacherLearnerRosterProvider);
    if (!_initialCourseApplied &&
        widget.initialCourseTitle != null &&
        courses.isNotEmpty) {
      _initialCourseApplied = true;
      final matches = courses.where(
        (course) => course.title == widget.initialCourseTitle,
      );
      if (matches.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref
                .read(teacherLearnerRosterProvider.notifier)
                .setFilters(query: '', courseId: matches.first.id);
          }
        });
      }
    }

    return AppScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Learner Analytics & Roster',
          style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: roster.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(teacherLearnerRosterProvider),
            child: const Text('Could not load learners. Retry'),
          ),
        ),
        data: (state) => ListView(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
          children: [
            AppSearchField(
              controller: _search,
              hintText: 'Search learners by name or course...',
              onChanged: (value) => _searchChanged(value, state.courseId),
            ),
            SizedBox(height: 14.h),
            if (courses.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CourseFilterChip(
                      label: 'All Courses',
                      selected: state.courseId == null,
                      onSelected: () => _selectCourse(null),
                    ),
                    for (final course in courses) ...[
                      SizedBox(width: 8.w),
                      _CourseFilterChip(
                        label: course.title,
                        selected: state.courseId == course.id,
                        onSelected: () => _selectCourse(course.id),
                      ),
                    ],
                  ],
                ),
              ),
            SizedBox(height: 18.h),
            if (state.isFiltering)
              const LinearProgressIndicator()
            else if (state.filterFailed)
              TextButton(
                onPressed: () => ref
                    .read(teacherLearnerRosterProvider.notifier)
                    .setFilters(query: state.query, courseId: state.courseId),
                child: const Text('Could not load learners. Retry'),
              ),
            Text(
              'Enrolled Learners (${state.items.length})',
              style: AppTextStyles.interBold24.copyWith(
                fontSize: 15.sp,
                color: AppColors.onBackground,
              ),
            ),
            SizedBox(height: 12.h),
            if (state.items.isEmpty &&
                !state.isFiltering &&
                !state.filterFailed)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: Text(
                  state.query.isEmpty && state.courseId == null
                      ? 'No learners enrolled yet.'
                      : 'No learners match these filters.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.interRegular14.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
              )
            else
              for (final item in state.items) _LearnerCard(item: item),
            if (state.hasMore)
              Center(
                child: TextButton(
                  onPressed: state.isLoadingMore
                      ? null
                      : () => ref
                            .read(teacherLearnerRosterProvider.notifier)
                            .loadMore(),
                  child: state.isLoadingMore
                      ? SizedBox(
                          width: 18.w,
                          height: 18.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          state.loadMoreFailed ? 'Retry loading' : 'Load more',
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _selectCourse(String? courseId) {
    _searchDelay?.cancel();
    ref
        .read(teacherLearnerRosterProvider.notifier)
        .setFilters(query: _search.text, courseId: courseId);
  }
}

class _CourseFilterChip extends StatelessWidget {
  const _CourseFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onSelected(),
    selectedColor: AppColors.primary,
    backgroundColor: const Color(0xFFF8F9FA),
    labelStyle: AppTextStyles.interMedium16.copyWith(
      fontSize: 11.sp,
      color: selected ? Colors.white : AppColors.grey700,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20.r),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.grey300),
    ),
    showCheckmark: false,
  );
}

class _LearnerCard extends StatelessWidget {
  const _LearnerCard({required this.item});

  final TeacherLearnerEnrollment item;

  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.only(bottom: 10.h),
    padding: EdgeInsets.all(14.w),
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: AppColors.grey300),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 21.r,
          backgroundColor: AppColors.primary,
          child: Text(
            item.studentName.isEmpty ? '?' : item.studentName[0].toUpperCase(),
            style: AppTextStyles.interSemiBold16.copyWith(color: Colors.white),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.studentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.interSemiBold16.copyWith(fontSize: 14.sp),
              ),
              SizedBox(height: 4.h),
              Text(
                item.courseTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.interMedium16.copyWith(
                  fontSize: 11.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                'Enrolled ${MaterialLocalizations.of(context).formatMediumDate(item.enrolledAt)}',
                style: AppTextStyles.interRegular14.copyWith(
                  fontSize: 11.sp,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
        ),
        if (item.status == 'completed')
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'Completed',
              style: AppTextStyles.interMedium16.copyWith(
                fontSize: 10.sp,
                color: AppColors.success,
              ),
            ),
          ),
      ],
    ),
  );
}

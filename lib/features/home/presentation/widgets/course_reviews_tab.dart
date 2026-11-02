import 'package:flutter_riverpod/legacy.dart';
import 'live_course_reviews.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/models/course_community_models.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/utils/keyboard_dismissal.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/course_community_controller.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/write_review_sheet.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';

part 'course_reviews_summary.dart';

final _legacyReviewFilter = StateProvider.autoDispose.family<int, Object>(
  (ref, key) => 0,
);

class CourseReviewsTab extends ConsumerStatefulWidget {
  final String courseId;
  final String courseTitle;
  final bool isTeacher;
  final bool isReadOnlyPreview;

  const CourseReviewsTab({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.isTeacher,
    this.isReadOnlyPreview = false,
  });

  @override
  ConsumerState<CourseReviewsTab> createState() => _CourseReviewsTabState();
}

class _CourseReviewsTabState extends ConsumerState<CourseReviewsTab> {
  final _filterIdentity = Object();
  int get _selectedFilterStars =>
      ref.read(_legacyReviewFilter(_filterIdentity));

  void _showInstructorReplyDialog(CourseReviewModel review) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Reply to ${review.studentName}',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 18.sp,
            color: AppColors.onBackground,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${review.comment}"',
              style: AppTextStyles.interRegular14.copyWith(
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
                color: AppColors.grey600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12.h),
            TextField(
              onTapOutside: dismissKeyboardOnTapOutside,
              controller: replyController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Type your official instructor response...',
                hintStyle: AppTextStyles.interRegular14.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.grey400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: AppColors.grey300, width: 1.w),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.grey600, fontSize: 14.sp),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final text = replyController.text.trim();
              if (text.isEmpty) return;
              ref
                  .read(courseCommunityProvider.notifier)
                  .replyAsInstructor(reviewId: review.id, replyText: text);
              Navigator.pop(ctx);
              CustomToast.showSuccess(
                context,
                message: 'Instructor response published!',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Post Reply',
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppConfig.isSupabaseEnabled) {
      return LiveCourseReviews(
        courseId: widget.courseId,
        isReadOnlyPreview: widget.isReadOnlyPreview,
      );
    }
    ref.watch(_legacyReviewFilter(_filterIdentity));
    final communityState = ref.watch(courseCommunityProvider);
    final allReviews = communityState.reviews
        .where((r) => r.courseId == widget.courseId)
        .toList();
    final distribution = RatingDistributionModel.fromReviews(allReviews);
    final filteredReviews = _selectedFilterStars == 0
        ? allReviews
        : allReviews
              .where((r) => r.rating.round() == _selectedFilterStars)
              .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRatingSummaryCard(distribution),
          SizedBox(height: 16.h),
          if (!widget.isTeacher)
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: SizedBox(
                width: double.infinity,
                height: 44.h,
                child: IgnorePointer(
                  ignoring: widget.isReadOnlyPreview,
                  child: OutlinedButton.icon(
                    onPressed: () => WriteReviewSheet.show(
                      context,
                      courseId: widget.courseId,
                      courseTitle: widget.courseTitle,
                    ),
                    icon: Icon(
                      Icons.rate_review_outlined,
                      color: AppColors.primary,
                      size: 18.w,
                    ),
                    label: Text(
                      'Write a Verified Review',
                      style: AppTextStyles.interSemiBold16.copyWith(
                        fontSize: 14.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary, width: 1.5.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          _buildFilterChips(allReviews.length),
          SizedBox(height: 16.h),
          Text(
            'Student Reviews (${filteredReviews.length})',
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 16.sp,
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 12.h),
          if (filteredReviews.isEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 32.h),
              alignment: Alignment.center,
              child: Text(
                'No reviews match this star filter.',
                style: AppTextStyles.interRegular14.copyWith(
                  color: AppColors.grey500,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredReviews.length,
              separatorBuilder: (_, __) => SizedBox(height: 14.h),
              itemBuilder: (context, index) {
                final review = filteredReviews[index];
                return _buildReviewCard(review);
              },
            ),
          SizedBox(height: 80.h),
        ],
      ),
    );
  }

  Widget _buildFilterChips(int totalCount) {
    final filters = [
      {'label': 'All ($totalCount)', 'stars': 0},
      {'label': '5 ★', 'stars': 5},
      {'label': '4 ★', 'stars': 4},
      {'label': '3 ★', 'stars': 3},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilterStars == f['stars'];
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(
                f['label'] as String,
                style: AppTextStyles.interMedium16.copyWith(
                  fontSize: 12.sp,
                  color: isSelected ? Colors.white : AppColors.grey700,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.grey100,
              onSelected: (_) =>
                  ref
                          .read(_legacyReviewFilter(_filterIdentity).notifier)
                          .state =
                      f['stars'] as int,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.grey300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewCard(CourseReviewModel review) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.grey200, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  review.studentName.isNotEmpty ? review.studentName[0] : 'U',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.studentName,
                            style: AppTextStyles.interSemiBold16.copyWith(
                              fontSize: 14.sp,
                              color: AppColors.onBackground,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (review.isVerified) ...[
                          SizedBox(width: 6.w),
                          Icon(
                            Icons.verified,
                            color: const Color(0xFF10B981),
                            size: 14.w,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      review.date,
                      style: AppTextStyles.interRegular14.copyWith(
                        fontSize: 11.sp,
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 15.w,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            review.comment,
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 13.sp,
              color: AppColors.grey800,
              height: 1.5,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              InkWell(
                onTap: widget.isReadOnlyPreview
                    ? null
                    : () => ref
                          .read(courseCommunityProvider.notifier)
                          .toggleHelpful(review.id),
                borderRadius: BorderRadius.circular(6.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                  child: Row(
                    children: [
                      Icon(
                        review.userLiked
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_outlined,
                        size: 14.w,
                        color: review.userLiked
                            ? AppColors.primary
                            : AppColors.grey500,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Helpful (${review.helpfulCount})',
                        style: AppTextStyles.interMedium16.copyWith(
                          fontSize: 12.sp,
                          color: review.userLiked
                              ? AppColors.primary
                              : AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (widget.isTeacher && review.instructorReply == null)
                TextButton.icon(
                  onPressed: () => _showInstructorReplyDialog(review),
                  icon: Icon(
                    Icons.reply_rounded,
                    size: 16.w,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Reply as Instructor',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.primary),
                  ),
                ),
            ],
          ),
          if (review.instructorReply != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFBBF7D0), width: 1.w),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school_rounded,
                        color: const Color(0xFF16A34A),
                        size: 16.w,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'Instructor Response',
                          style: AppTextStyles.interSemiBold16.copyWith(
                            fontSize: 12.sp,
                            color: const Color(0xFF166534),
                          ),
                        ),
                      ),
                      Text(
                        review.instructorReplyDate ?? '',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    review.instructorReply!,
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 12.sp,
                      color: const Color(0xFF14532D),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

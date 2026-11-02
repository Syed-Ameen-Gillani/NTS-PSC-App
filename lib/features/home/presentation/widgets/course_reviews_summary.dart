part of 'course_reviews_tab.dart';

extension _CourseReviewSummary on _CourseReviewsTabState {
  Widget _buildRatingSummaryCard(RatingDistributionModel dist) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.grey200, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dist.averageRating.toString(),
                style: AppTextStyles.interBold24.copyWith(
                  fontSize: 34.sp,
                  color: AppColors.onBackground,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 16.w,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${dist.totalReviews} ratings',
                style: AppTextStyles.interRegular14.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              children: [
                _buildStarBar(5, dist.fiveStarRatio),
                _buildStarBar(4, dist.fourStarRatio),
                _buildStarBar(3, dist.threeStarRatio),
                _buildStarBar(2, dist.twoStarRatio),
                _buildStarBar(1, dist.oneStarRatio),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarBar(int star, double ratio) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Text(
            '$star★',
            style: AppTextStyles.interMedium16.copyWith(
              fontSize: 11.sp,
              color: AppColors.grey600,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: AppColors.grey200,
                color: const Color(0xFFF59E0B),
                minHeight: 6.h,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

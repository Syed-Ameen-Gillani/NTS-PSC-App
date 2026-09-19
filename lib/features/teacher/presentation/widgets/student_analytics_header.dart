import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class StudentAnalyticsHeader extends StatelessWidget {
  final List<StudentRosterModel> students;

  const StudentAnalyticsHeader({super.key, required this.students});

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) return const SizedBox.shrink();

    final totalCount = students.length;
    final avgProgress = (students.map((s) => s.progress).reduce((a, b) => a + b) / totalCount * 100).toInt();
    final avgScore = (students.map((s) => s.averageQuizScore).reduce((a, b) => a + b) / totalCount).toInt();
    final atRiskCount = students.where((s) => s.status == 'Needs Attention').length;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.grey300, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined, size: 18.w, color: AppColors.primary),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        'Cohort Performance Overview',
                        style: AppTextStyles.interBold24.copyWith(
                          fontSize: 14.sp,
                          color: AppColors.onBackground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Coursera Insights',
                  style: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 10.sp,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Learners',
                  value: '$totalCount',
                  icon: Icons.people_alt_outlined,
                  color: AppColors.primary,
                  bgColor: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildMetricTile(
                  label: 'Avg. Progress',
                  value: '$avgProgress%',
                  icon: Icons.trending_up,
                  color: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Avg. Quiz Score',
                  value: '$avgScore%',
                  icon: Icons.school_outlined,
                  color: const Color(0xFF059669),
                  bgColor: const Color(0xFFD1FAE5),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildMetricTile(
                  label: 'Needs Support',
                  value: '$atRiskCount',
                  icon: Icons.warning_amber_rounded,
                  color: atRiskCount > 0 ? const Color(0xFFD97706) : AppColors.grey500,
                  bgColor: atRiskCount > 0 ? const Color(0xFFFEF3C7) : AppColors.grey100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16.w, color: color),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTextStyles.interBold24.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.onBackground,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.interRegular14.copyWith(
                    fontSize: 10.sp,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

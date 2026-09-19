import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class TeacherAnalyticsScreen extends StatelessWidget {
  const TeacherAnalyticsScreen({super.key});

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFDADCE0), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 12.sp,
              color: AppColors.grey500,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: AppTextStyles.interBold24.copyWith(
                  fontSize: 20.sp,
                  color: AppColors.onBackground,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isPositive ? const Color(0xFFD1FAE5) : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  change,
                  style: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 11.sp,
                    color: isPositive ? const Color(0xFF059669) : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onBackground, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Student Performance Analytics',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 18.sp,
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enrollment & Engagement',
                style: AppTextStyles.interBold24.copyWith(
                  fontSize: 18.sp,
                  color: AppColors.onBackground,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Course Completion',
                      value: '78.4%',
                      change: '+4.2%',
                      isPositive: true,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Avg Quiz Score',
                      value: '72 / 100',
                      change: '+8.1%',
                      isPositive: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Active Test-Takers',
                      value: '840',
                      change: '+14%',
                      isPositive: true,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Drop-off Rate',
                      value: '6.2%',
                      change: '-1.5%',
                      isPositive: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 28.h),

              // Hardest Quiz Questions
              Text(
                'Top Challenging Quiz Questions',
                style: AppTextStyles.interBold24.copyWith(
                  fontSize: 18.sp,
                  color: AppColors.onBackground,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Questions where candidates recorded the highest failure rate:',
                style: AppTextStyles.interRegular14.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.grey500,
                ),
              ),
              SizedBox(height: 14.h),

              _buildChallengingQuestionTile(
                quiz: 'Current Affairs Weekly',
                question: 'Which country recently joined the SCO as full member in 2024?',
                failRate: '64% Incorrect',
                correctRate: '36% Correct',
              ),
              _buildChallengingQuestionTile(
                quiz: 'FPSC Customs Foundations',
                question: 'Jurisdiction of Customs Collectorate over transit trade agreements',
                failRate: '58% Incorrect',
                correctRate: '42% Correct',
              ),
              _buildChallengingQuestionTile(
                quiz: 'Pakistan Affairs Masters',
                question: 'Key provisions of Bogra Formula and subsequent reaction of constituent assembly',
                failRate: '52% Incorrect',
                correctRate: '48% Correct',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengingQuestionTile({
    required String quiz,
    required String question,
    required String failRate,
    required String correctRate,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.grey300, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                quiz,
                style: AppTextStyles.interSemiBold16.copyWith(
                  fontSize: 11.sp,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  failRate,
                  style: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 11.sp,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            question,
            style: AppTextStyles.interMedium16.copyWith(
              fontSize: 13.sp,
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                flex: 36,
                child: Container(
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(2.r)),
                  ),
                ),
              ),
              Expanded(
                flex: 64,
                child: Container(
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(2.r)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

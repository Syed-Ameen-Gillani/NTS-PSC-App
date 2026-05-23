import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';

class QuizReadyScreen extends ConsumerWidget {
  const QuizReadyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          'Quiz Ready',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1.h,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 32.h),
              Container(
                width: 96.w,
                height: 96.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF9333EA),
                    size: 48.w,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Your AI Quiz is\nReady!',
                textAlign: TextAlign.center,
                style: AppTextStyles.interBold30.copyWith(
                  fontSize: 28.sp,
                  color: AppColors.onBackground,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'We generated a custom Current Affairs quiz\nbased on your preferences.',
                textAlign: TextAlign.center,
                style: AppTextStyles.interRegular14.copyWith(
                  color: AppColors.grey500,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 48.h),
              
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: const Color(0xFFDADCE0), width: 1.w),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      child: Text(
                        'AI GENERATED',
                        style: AppTextStyles.interBold24.copyWith(
                          fontSize: 10.sp,
                          color: const Color(0xFF9333EA),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Current Affairs\nChallenge',
                      style: AppTextStyles.interBold24.copyWith(
                        fontSize: 20.sp,
                        color: AppColors.onBackground,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    _buildSpecRow(Icons.description_outlined, '15 Questions'),
                    SizedBox(height: 12.h),
                    _buildSpecRow(Icons.bar_chart, 'Medium Difficulty'),
                    SizedBox(height: 12.h),
                    _buildSpecRow(Icons.access_time, 'Est. 10 Minutes'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(24.w).copyWith(
          bottom: 24.h + MediaQuery.of(context).padding.bottom,
        ),
        child: CustomButton(
          text: 'Start Quiz',
          onPressed: () => context.pushNamed(AppRoute.activeQuiz.name), 
          trailingIcon: Icon(Icons.arrow_forward, color: Colors.white, size: 20.w),
        ),
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: const BoxDecoration(
            color: Color(0xFFE3F2FD),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 16.w),
        ),
        SizedBox(width: 12.w),
        Text(
          text,
          style: AppTextStyles.interMedium16.copyWith(
            fontSize: 14.sp,
            color: AppColors.grey700,
          ),
        ),
      ],
    );
  }
}

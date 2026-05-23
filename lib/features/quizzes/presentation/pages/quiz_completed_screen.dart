import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';

class QuizCompletedScreen extends ConsumerWidget {
  const QuizCompletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.grey900, size: 24.w),
            onPressed: () => context.goNamed(AppRoute.main.name),
          ),
          SizedBox(width: 8.w),
        ],
        title: Text(
          'Quiz Completed',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.grey900,
          ),
        ),
        centerTitle: true,
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
                  color: Color(0xFFFFF7E6), // Light orange/yellow
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.emoji_events, // Trophy
                    color: Color(0xFFFA8C16), // Orange
                    size: 48.w,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Congratulations!',
                textAlign: TextAlign.center,
                style: AppTextStyles.interBold30.copyWith(
                  fontSize: 28.sp,
                  color: AppColors.grey900,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'You have successfully completed the\nCurrent Affairs Challenge.',
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
                    Text(
                      'Your Results',
                      style: AppTextStyles.interBold24.copyWith(
                        fontSize: 20.sp,
                        color: AppColors.grey900,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    _buildSpecRow(Icons.check_circle_outline, 'Score: 12 / 15', const Color(0xFF10B981), const Color(0xFFD1FAE5)),
                    SizedBox(height: 16.h),
                    _buildSpecRow(Icons.pie_chart_outline, 'Accuracy: 80%', AppColors.primary, const Color(0xFFE3F2FD)),
                    SizedBox(height: 16.h),
                    _buildSpecRow(Icons.access_time, 'Time: 08:45', const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }

  Widget _buildSpecRow(IconData icon, String text, Color iconColor, Color bgColor) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20.w),
        ),
        SizedBox(width: 12.w),
        Text(
          text,
          style: AppTextStyles.interMedium16.copyWith(
            fontSize: 16.sp,
            color: AppColors.grey700,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';

class TeacherWelcomeScreen extends ConsumerWidget {
  const TeacherWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageHeight = 0.45.sh;
    final floatingIconSize = 64.w;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight,
            child: Image.asset(
              AppAssets.course1,
              fit: BoxFit.cover,
            ),
          ),

          // 2. White Container with Instructor Proposition
          Positioned(
            top: imageHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.only(
                top: (floatingIconSize / 2) + 16.h,
                left: 24.w,
                right: 24.w,
                bottom: 24.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teach & Mentor',
                    style: AppTextStyles.interBold24.copyWith(
                      color: AppColors.onBackground,
                      fontSize: 28.sp,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Future Officers.',
                    style: AppTextStyles.interBold24.copyWith(
                      color: AppColors.primary,
                      fontSize: 28.sp,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Join Educora as an expert instructor. Publish FPSC, NTS, CSS, and AJK PSC courses, host live mock tests, and mentor thousands of students across Pakistan.',
                    style: AppTextStyles.interRegular14.copyWith(
                      color: AppColors.grey500,
                      fontSize: 14.sp,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Register as Instructor
                  CustomButton(
                    text: 'Register as Instructor',
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).selectRole(UserRole.teacher);
                      context.pushNamed(AppRoute.teacherSignup.name);
                    },
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 16.h),

                  // Teacher Log In
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).selectRole(UserRole.teacher);
                        context.pushNamed(AppRoute.teacherLogin.name);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        backgroundColor: AppColors.grey100.withValues(alpha: 0.5),
                        side: BorderSide(color: AppColors.grey300, width: 1.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Log In',
                        style: AppTextStyles.interSemiBold16.copyWith(
                          color: AppColors.onBackground,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Icon Badge
          Positioned(
            top: imageHeight - (floatingIconSize / 2),
            left: 24.w,
            child: Container(
              width: floatingIconSize,
              height: floatingIconSize,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 32.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

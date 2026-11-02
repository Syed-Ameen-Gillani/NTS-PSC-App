import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
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

class WelcomeRoleScreen extends ConsumerWidget {
  static const _welcomeTitle = 'Welcome to\nCareer Boost Officers Academy.';

  const WelcomeRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // White Container Area
              Container(
                height: 380.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(43.r),
                    bottomRight: Radius.circular(43.r),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: 40.w, right: 40.w, bottom: 20.h),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(
                      AppAssets.welcomeRole,
                      fit: BoxFit.contain,
                      height: 280.h,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // Text Content
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _welcomeTitle,
                        textAlign: TextAlign.start,
                        style: AppTextStyles.interBold24.copyWith(
                          fontSize: 26.sp,
                          color: AppColors.onBackground,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Login as a',
                        textAlign: TextAlign.start,
                        style: AppTextStyles.interMedium16.copyWith(
                          fontSize: 18.sp,
                          color: AppColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // Role Selection Buttons
              Padding(
                padding: EdgeInsets.only(bottom: 24.h, left: 24.w, right: 24.w),
                child: Column(
                  children: [
                    // Student Button (Primary Blue)
                    CustomButton(
                      text: 'Student',
                      width: double.infinity,
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).selectRole(UserRole.student);
                        context.pushNamed(AppRoute.welcome.name);
                      },
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 16.h),

                    // Teacher Button (Outlined White/Blue)
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).selectRole(UserRole.teacher);
                          context.pushNamed(AppRoute.teacherWelcome.name);
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary, width: 2.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                        ),
                        child: Text(
                          'Teacher',
                          style: AppTextStyles.interSemiBold16.copyWith(
                            fontSize: 17.sp,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

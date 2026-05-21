import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Exact sizing requirements
    final imageHeight = 0.45.sh; // Reduced to 45% to prevent overflow and give more room to content
    final floatingIconSize = 64.w; // Square size for the floating book icon

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Image Layer
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight,
            child: Image.asset(
              AppAssets.course1, // The specific background image from the screenshot
              fit: BoxFit.cover,
            ),
          ),

          // 2. Bottom White Container
          Positioned(
            top: imageHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.only(
                top: (floatingIconSize / 2) + 16.h, // Slightly reduced padding
                left: 24.w,
                right: 24.w,
                bottom: 16.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Headings
                  Text(
                    'Master Your Exams',
                    style: AppTextStyles.interBold24.copyWith(
                      color: AppColors.onBackground,
                      fontSize: 28.sp,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Anytime, Anywhere.',
                    style: AppTextStyles.interBold24.copyWith(
                      color: AppColors.primary,
                      fontSize: 28.sp,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),

                  SizedBox(height: 12.h), // Tight spacing to keep text together

                  // Subtitle
                  Text(
                    'Join thousands of students preparing for FPSC, NTS, CSS, and AJK PSC with expert teachers and comprehensive mock tests.',
                    style: AppTextStyles.interRegular14.copyWith(
                      color: AppColors.grey500,
                      fontSize: 15.sp,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 32.h), // Fixed, reasonable gap instead of pushing to extremes

                  // Create an Account Button
                  CustomButton(
                    text: 'Create an Account',
                    onPressed: () {
                      context.pushNamed(AppRoute.signup.name);
                    },
                    color: AppColors.primary,
                  ),

                  SizedBox(height: 16.h),

                  // Log In Button
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: OutlinedButton(
                      onPressed: () {
                        context.pushReplacementNamed(AppRoute.login.name);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        backgroundColor: AppColors.grey100.withOpacity(0.5), 
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

                  SizedBox(height: 24.h),

                  // Explore Courses as Guest
                  Center(
                    child: InkWell(
                      onTap: () {
                        // Navigate to guest flow
                      },
                      child: Container(
                        padding: EdgeInsets.only(
                          bottom: 2.h, // Space between text and underline
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.grey500,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Text(
                          'Explore Courses as Guest',
                          style: AppTextStyles.interMedium16.copyWith(
                            color: AppColors.grey500,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Blue Icon Container
          // Must be positioned perfectly on the edge: half inside the image, half inside the white area.
          Positioned(
            top: imageHeight - (floatingIconSize / 2),
            left: 24.w,
            child: Container(
              width: floatingIconSize,
              height: floatingIconSize,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16.r),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                AppAssets.bookSvg,
                width: 28.w,
                height: 28.w,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

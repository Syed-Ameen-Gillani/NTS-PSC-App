import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
//import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/constants/colors.dart';
import 'package:nts_psc_app/features/onboarding/presentation/widgets/onboarding_content_style_2.dart';
import 'package:nts_psc_app/features/onboarding/presentation/widgets/page_indicator.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';

class OnboardingScreen5 extends StatelessWidget {
  const OnboardingScreen5({super.key});

  @override
  Widget build(BuildContext context) {
    const String title = 'Create your own study plan';
    const String description =
        'Study according to the study plan, make study more motivated.';
   

    return AppScaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          // Content Area
          OnboardingContentStyle2(
            imageAsset: AppAssets.onboarding5,
            title: title,
            description: description,
            showSkipButton: false, // Hide skip button on this screen
            onSkip: () {},
          ),

          // Page Indicator
          Positioned(
            bottom: 104.h,
            left: 0,
            right: 0,
            child: const Center(child: PageIndicator(currentPage: 2, totalPages: 3)),
          ),

          // Sign Up Button - Fixed Position
          Positioned(
            bottom: 24.h,
            left: 24.w,
            right: 0.5.sw + 8.w,
            child: CustomButton(
              height: 50.h,
              text: 'Sign up',
              onPressed: () {
                // sign up action
              },
              trailingIcon: null, 
            ),
          ),

          // Log In Button - Fixed Position
          Positioned(
            bottom: 24.h,
            left: 0.5.sw + 8.w,
            right: 24.w,
            child: SizedBox(
              height: 50.h,
              child: ElevatedButton(
                onPressed: () {
                  // login action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kWhiteContainerColor, // White background
                  foregroundColor: kPrimaryBlue,
                  side: BorderSide(color: kPrimaryBlue, width: 2.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Log in',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

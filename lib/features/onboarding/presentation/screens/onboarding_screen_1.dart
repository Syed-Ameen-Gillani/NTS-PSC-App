
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
//import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/constants/colors.dart';
import 'package:nts_psc_app/features/onboarding/presentation/widgets/onboarding_content_style_1.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';

class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Unique Content for Screen 1 ---
    const String title = 'Learn Online From\n Your Home';
    const String description =
        'Amet minim mollit non deserunt ullamco est sit aliqua dolor do amet sint. Velit officia consequat duis enim velit mollit.';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Column(
        children: [
          // 1. Content Area (Using the reusable Style 1 widget)
          Expanded(
            child: OnboardingContentStyle1(
              imageAsset: AppAssets.onboarding1,
              title: title,
              description: description,
            ),
          ),

          // 2. Navigation Area (Bottom Button)
          SafeArea(
            top: false,
            bottom: true,
            child: Padding(
              padding: EdgeInsets.only(top: 20.h, bottom: 10.h),
              child: CustomButton(
                width: 197.w,
                text: 'Next',
                onPressed: () {
                  // next action
                },
                trailingIcon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18.sp,
                  color: Colors.white,
                ), 
              ),
            ),
          ),
        ],
      ),
    );
  }
}

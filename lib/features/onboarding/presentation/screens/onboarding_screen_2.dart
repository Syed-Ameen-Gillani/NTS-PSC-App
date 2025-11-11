
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
//import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/constants/colors.dart';
import 'package:nts_psc_app/features/onboarding/presentation/widgets/onboarding_content_style_1.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Unique Content for Screen 2 ---
    const String title = 'The Best Platform For Online Learning';
    const String description =
        'Amet minim mollit non deserunt ullamco est sit aliqua dolor do amet sint. Velit officia consequat duis enim velit mollit.';
    

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Column(
        children: [
          // 1. Content Area (Reusing the White Container style)
          Expanded(
            child: OnboardingContentStyle1(
              imageAsset: AppAssets.onboarding2,
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
                text: 'Get Started', // Different button text
                onPressed: () {
                  // get started action
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

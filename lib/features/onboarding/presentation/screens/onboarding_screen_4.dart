
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
//import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/constants/colors.dart';
import 'package:nts_psc_app/features/onboarding/presentation/widgets/onboarding_content_style_2.dart';
import 'package:nts_psc_app/features/onboarding/presentation/widgets/page_indicator.dart';

class OnboardingScreen4 extends StatelessWidget {
  const OnboardingScreen4({super.key});

  @override
  Widget build(BuildContext context) {
    const String title = 'Quick and easy learning';
    const String description =
        'Easy and fast learning at any time to help you improve various skills';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          // Content Area
          OnboardingContentStyle2(
            imageAsset: AppAssets.onboarding4,
            title: title,
            description: description,
            showSkipButton: true,
            onSkip: () {
              // skip action
            },
          ),

          // Page Indicator - Fixed Position
          Positioned(
            top: 592.h,
            left: 155.w,
            child: const PageIndicator(currentPage: 1, totalPages: 3),
          ),
        ],
      ),
    );
  }
}

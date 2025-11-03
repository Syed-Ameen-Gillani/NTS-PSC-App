// lib/features/onboarding/presentation/screens/onboarding_screen_3.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
//import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/constants/colors.dart';
import 'package:nts_psc_app/features/onboarding/presentation/widgets/onboarding_content_style_2.dart';
import 'package:nts_psc_app/features/onboarding/presentation/widgets/page_indicator.dart';

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    const String title = 'Numerous free trial courses';
    const String description =
        'Free courses for you to find your way to learning';
    const String imageAsset = 'assets/images/onboarding_3.png';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          // Content Area
          OnboardingContentStyle2(
            imageAsset: imageAsset,
            title: title,
            description: description,
            showSkipButton: true,
            onSkip: () {
              // Skip action
            },
          ),

          // Page Indicator - Fixed Position
          Positioned(
            top: 592.h,
            left: 155.w,
            child: const PageIndicator(currentPage: 0, totalPages: 3),
          ),
        ],
      ),
    );
  }
}

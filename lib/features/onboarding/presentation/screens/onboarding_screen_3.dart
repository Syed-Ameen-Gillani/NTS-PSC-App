import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
//import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/features/onboarding/presentation/widgets/onboarding_content_style_2.dart';
import 'package:nts_psc_app/features/onboarding/presentation/widgets/page_indicator.dart';

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    const String title = 'Numerous free\n trial courses';
    const String description =
        'Free courses for you to find your\n way to learning';

    return AppScaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Content Area
            OnboardingContentStyle2(
              imageAsset: AppAssets.onboarding3,
              title: title,
              description: description,
              showSkipButton: true,
              onSkip: () {
                // Skip action
              },
            ),

            // Page Indicator - Fixed Position
            Positioned(
              bottom: 80.h,
              left: 0,
              right: 0,
              child: const Center(child: PageIndicator(currentPage: 0, totalPages: 3)),
            ),
          ],
        ),
      ),
    );
  }
}

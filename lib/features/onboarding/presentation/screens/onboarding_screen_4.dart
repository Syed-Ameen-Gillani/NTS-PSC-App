
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
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
    const String title = 'Quick and easy\n learning';
    const String description =
        'Easy and fast learning at any time\n  to help you improve various skills';

    return AppScaffold(
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
            bottom: 80.h,
            left: 0,
            right: 0,
            child: const Center(child: PageIndicator(currentPage: 1, totalPages: 3)),
          ),
        ],
      ),
    );
  }
}

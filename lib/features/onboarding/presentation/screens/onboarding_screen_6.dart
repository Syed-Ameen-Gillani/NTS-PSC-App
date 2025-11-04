import 'package:flutter/material.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
//import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/constants/colors.dart';
import 'package:nts_psc_app/features/onboarding/presentation/widgets/onboarding_content_style_3.dart';

class OnboardingScreen6 extends StatelessWidget {
  const OnboardingScreen6({super.key});

  @override
  Widget build(BuildContext context) {
    const String title = 'You learn';
    const String description = 'While Sitting at Home';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: OnboardingContentStyle3(
          imageAsset: AppAssets.onboarding6,
          title: title,
          description: description,
          onContinue: () {
            // continue action
          },
        ),
      ),
    );
  }
}

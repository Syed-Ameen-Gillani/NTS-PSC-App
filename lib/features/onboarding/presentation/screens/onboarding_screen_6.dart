// lib/features/onboarding/presentation/screens/onboarding_screen_6.dart

import 'package:flutter/material.dart';
//import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/constants/colors.dart';
import 'package:nts_psc_app/features/onboarding/presentation/widgets/onboarding_content_style_3.dart';

class OnboardingScreen6 extends StatelessWidget {
  const OnboardingScreen6({super.key});

  @override
  Widget build(BuildContext context) {
    const String title = 'You learn';
    const String description = 'While Sitting at Home';
    const String imageAsset = 'assets/images/onboarding_6.png';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: OnboardingContentStyle3(
          imageAsset: imageAsset,
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

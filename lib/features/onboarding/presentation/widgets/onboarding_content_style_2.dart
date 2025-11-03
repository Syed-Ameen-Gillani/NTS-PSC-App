// lib/features/onboarding/presentation/widgets/onboarding_content_style_2.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/constants/colors.dart';

class OnboardingContentStyle2 extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String description;
  final bool showSkipButton;
  final VoidCallback onSkip; 

  const OnboardingContentStyle2({
    super.key, 
    required this.imageAsset,
    required this.title,
    required this.description,
    required this.onSkip,
    this.showSkipButton = true, 
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Skip Button (Top Right Corner)
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(top: 16.h, right: 24.w),
            child: showSkipButton 
                ? TextButton(
                    onPressed: onSkip,
                    child: Text('Skip', style: TextStyle(fontSize: 16.sp, color: kPrimaryBlue)),
                  )
                : SizedBox(height: 16.h),
          ),
        ),
        
        // 2. Image (Center)
        SizedBox(height: 30.h), 
        Center(
          child: Image.asset(
            imageAsset,
            height: 250.h, 
            width: 250.w,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 60.h),
        
        // 3. Text Content
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w900, color: kTitleColor, height: 1.2),
              ),
              SizedBox(height: 16.h),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w400, color: kDescriptionColor, height: 1.5),
              ),
            ],
          ),
        ),

        const Spacer(),
      ],
    );
  }
}
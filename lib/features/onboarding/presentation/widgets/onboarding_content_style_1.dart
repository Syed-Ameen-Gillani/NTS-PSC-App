// lib/features/onboarding/presentation/widgets/onboarding_content_style_1.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/constants/colors.dart';

class OnboardingContentStyle1 extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String description;

  const OnboardingContentStyle1({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    
    final whiteContainerHeight = MediaQuery.of(context).size.height * 0.55; 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        //  The White Container (Top Area)
        Container(
          height: whiteContainerHeight, 
          width: double.infinity,
          decoration: BoxDecoration(
            color: kWhiteContainerColor,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(43.r),
              bottomRight: Radius.circular(43.r),
            ),
          ),
          child: Center( 
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 40.w), 
              child: Image.asset(
                imageAsset,
                fit: BoxFit.contain, 
              ),
            ),
          ),
        ),
        
        // 2. Vertical Spacer
        SizedBox(height: 48.h),

        // 3. Text Content
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28.sp, 
                  fontWeight: FontWeight.w900,
                  color: kTitleColor,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 24.h),

              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: kDescriptionColor,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        
        const Spacer(), // Pushes content up, ensuring responsiveness
        SizedBox(height: 24.h),
      ],
    );
  }
}
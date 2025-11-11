import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/constants/colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

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
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color titleColor = Theme.of(context).textTheme.displayLarge!.color!;
    final Color descriptionColor = Theme.of(
      context,
    ).textTheme.bodyLarge!.color!;

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
                    child: Text(
                      'Skip',
                      style: TextStyle(fontSize: 16.sp, color: primaryColor),
                    ),
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
                style: AppTextStyles.dmSans500med24.copyWith(
                  fontSize: 24.88.sp, //  responsive scaling
                  color:
                      kTitleColor, //kTitleColor constant (which maps to AppColors.onBackground)
                ),
              ),

              SizedBox(height: 16.h),
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTextStyles.dmSans500med12.copyWith(
                  fontSize: 12.sp, //  responsive scaling
                  color:
                      kDescriptionColor, // description color constant
                ),
              ),
            ],
          ),
        ),

        const Spacer(),
      ],
    );
  }
}

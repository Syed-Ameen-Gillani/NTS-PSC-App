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
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color titleColor = Theme.of(context).textTheme.displayLarge!.color!;
    final Color descriptionColor = Theme.of(
      context,
    ).textTheme.bodyLarge!.color!;
    final whiteContainerHeight = 448.0;

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
          child: Padding(
            padding: EdgeInsets.only(left: 40.w, right: 40.w, bottom: 30.h),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                imageAsset,
                fit: BoxFit.contain,
                height: whiteContainerHeight * 0.7,
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
                style: Theme.of(
                  context,
                ).textTheme.displayLarge!.copyWith(color: titleColor),
              ),
              SizedBox(height: 25.h),

              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge!.copyWith(color: descriptionColor),
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

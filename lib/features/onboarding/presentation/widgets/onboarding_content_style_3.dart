import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/constants/colors.dart';

class OnboardingContentStyle3 extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String description;
  final VoidCallback onContinue;

  const OnboardingContentStyle3({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.description,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 80.h),

          // Top circular illustration
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(120.r),
              child: Image.asset(
                imageAsset,
                height: 230.h,
                width: 230.w,
                fit: BoxFit.contain,
              ),
            ),
          ),

          SizedBox(height: 220.h),

          // Text
          Text(
            title,
            style: TextStyle(
              fontSize: 29.86.sp,
              fontWeight: FontWeight.w500,
              color: kTitleColor,
            ),
          ),
          SizedBox(height: 14.h),

          SizedBox(
            width: 239.w,
            child: Text(
              description,
              //softWrap: true,
              //textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 24.88.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF767372),
                height: 1.4,
              ),
            ),
          ),

          const Spacer(),

          // Bottom area: full-width Stack to position arrow and button precisely
          SizedBox(
            height: 160.h, // controls vertical room for arrow + button
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Curved arrow positioned above the button (adjust right/bottom as needed)
                Positioned(
                  right: 60.w, // how far from right edge the arrow should be
                  bottom: 120
                      .h, // how far above the bottom of this box the arrow sits
                  child: Image.asset(
                    'assets/images/curved_arrow.png',
                    width: 70.w,
                    height: 120.h,
                    fit: BoxFit.contain,
                  ),
                ),

                // Continue circular button at bottom-right
                Positioned(
                  right: 20.w,
                  bottom: 10.h,
                  child: SizedBox(
                    width: 100.w,
                    height: 100.w,
                    child: FloatingActionButton(
                      onPressed: onContinue,
                      backgroundColor: kPrimaryBlue,
                      elevation: 6,
                      shape: const CircleBorder(),
                      child: Text(
                        'Continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
//import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/constants/colors.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';

class WelcomeRoleScreen extends StatelessWidget {
  const WelcomeRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Content details for this screen

    final whiteContainerHeight = 448.0;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Column(
        children: [
          // White Container Area (Reusing Style 1 structure widget)
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
                    AppAssets.welcomeRole,
                    fit: BoxFit.contain,
                    height: whiteContainerHeight * 0.7,
                  ),
                ),
              ),
          ),

          //  Vertical Spacer
          SizedBox(height: 80.h),

          //  Text Content
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to \nEducora.',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 24.88.sp,
                      fontWeight: FontWeight.w500,
                      color: kTitleColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Login as a',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 24.88.sp,
                      fontWeight: FontWeight.w500,
                      color: kTitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(), // Pushes buttons to the bottom
          //  Role Selection Buttons
          SafeArea(
            top: false,
            bottom: true,
            child: Padding(
              padding: EdgeInsets.only(bottom: 30.h, left: 24.w, right: 24.w),
              child: Column(
                children: [
                  // Student Button (Primary Blue)
                  CustomButton(
                    text: 'Student',
                    width: double.infinity,
                    onPressed: () {
                      // Student button action
                    },
                    trailingIcon: null,
                  ),
                  SizedBox(height: 16.h),

                  // Teacher Button (Outlined White/Blue)
                  SizedBox(
                    width: double.infinity,
                    height: 68.h,
                    child: OutlinedButton(
                      onPressed: () {
                        // Teacher button action
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: kWhiteContainerColor,
                        foregroundColor: kPrimaryBlue,
                        side: BorderSide(color: kPrimaryBlue, width: 2.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50.r),
                        ),
                      ),
                      child: Text(
                        'Teacher',
                        style: TextStyle(
                          fontSize: 17.28.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

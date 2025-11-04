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
  
    final whiteContainerHeight = MediaQuery.of(context).size.height * 0.50;

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
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 40.w),
                child: Image.asset(AppAssets.welcomeRole, fit: BoxFit.contain),
              ),
            ),
          ),

          //  Vertical Spacer
          SizedBox(height: 30.h),

          //  Text Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Educora.',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w500,
                    color: kTitleColor,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Login as a',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w500,
                    color: kTitleColor,
                  ),
                ),
              ],
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
                          fontSize: 18.sp,
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

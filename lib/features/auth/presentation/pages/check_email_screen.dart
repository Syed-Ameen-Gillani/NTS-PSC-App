// lib/features/authentication/presentation/screens/check_email_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';

class CheckEmailScreen extends StatelessWidget {
  const CheckEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define colors from AppColors
    final Color primaryColor = AppColors.primary;
    final Color titleColor = AppColors.onBackground;
    final Color greyColor = AppColors.grey500;

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w), // Global padding
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, //vertically center the content mass
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3), // Push content down from the top

              Text(
                'Check your email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge!.copyWith(
                  color: titleColor,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 10.h),

              Text(
                'We\'ve sent a password recover instruction to your email',
                textAlign: TextAlign.center,
                style: AppTextStyles.dmSans500med12.copyWith(
                  color: greyColor,
                  fontSize: 12.sp,
                  height: 1.4,
                ),
              ),

              SizedBox(height: 83.h),

              Center(
                child: Image.asset(
                  AppAssets.emailCheckIllustration,
                  height: 183.57.h,
                  width: 205.w,
                  fit: BoxFit.contain,
                ),
              ),

              SizedBox(height: 83.h),

              CustomButton(
                text: 'Login',
                onPressed: () {
                  //context.go('/login');
                },
                height: 60.h,
              ),

              SizedBox(height: 10.h),

              //Resend Button
              SizedBox(
                width: double
                    .infinity, // Ensures the button takes full available width
                height: 60.h,
                child: OutlinedButton(
                  onPressed: () {
                    // Action to resend the email
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,

                    side: BorderSide.none,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                  ),
                  child: Text(
                    'Resend',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 52.h),

              Text(
                'Didn\'t get any email? Check your spam\n folder or try again with a valid email.',
                textAlign: TextAlign.center,
                style: AppTextStyles.dmSans500med12.copyWith(
                  color: greyColor,
                  fontSize: 12.sp,
                ),
              ),

              const Spacer(flex: 4), // Final bottom push
            ],
          ),
        ),
      ),
    );
  }
}

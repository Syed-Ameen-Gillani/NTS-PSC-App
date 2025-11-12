import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';

class AccountCreatedSuccessScreen extends StatelessWidget {
  const AccountCreatedSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    //color variables for cleaner access
    final Color primaryColor = AppColors.primary;
    final Color titleColor = AppColors.onBackground;
    final Color subtitleColor = AppColors.grey500;

    //exact dimensions from Figma for the stars illustration
    const double imageWidthFigma = 74.93;
    const double imageHeightFigma = 72.78;

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Column(
              // Align content block to center, overriding Spacer behavior slightly
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 80.h),

                Center(
                  child: Image.asset(
                    AppAssets.sparklingstars,
                    width: imageWidthFigma.w,
                    height: imageHeightFigma.h,
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: 78.91.h),

                Text(
                  'Account Created Successfully!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.dmSans500med24.copyWith(
                    fontSize: 24.88.sp,
                    fontWeight: FontWeight.w500,
                    color: titleColor,
                  ),
                ),

                SizedBox(height: 6.15.h),

                Text(
                  'If you are going to use a passage of Lorem Ipsum, '
                  'you need to be sure there isn\'t anything embarrassing.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.dmSans500med12.copyWith(
                    fontSize: 14.sp,
                    color: subtitleColor,
                    height: 1.4,
                  ),
                ),

                // Spacing before button
                SizedBox(height: 35.08.h),

                //  Sign In Button
                CustomButton(
                  text: 'Sign In',
                  onPressed: () {
                    //context.go('/login');
                  },
                  height: 52.61.h,
                ),

                SizedBox(height: 50.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

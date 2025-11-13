import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/auth/presentation/widgets/auth_social_button.dart';
import 'package:nts_psc_app/presentation/widgets/home_indicator.dart';

class SignupMethodSelectionScreen extends StatelessWidget {
  const SignupMethodSelectionScreen({super.key});

  // --- Helper Function: Primary Method Button (White with Blue Text) ---
  Widget _buildPrimaryMethodButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: double.infinity,
      height: 60.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, 
          foregroundColor: primaryColor,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.r),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 17.28.sp,
            fontWeight: FontWeight.w500,
            color: Color(0xFF060302), 
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final Color screenBackground = AppColors.surfaceVariant;
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color textColor = AppColors.onBackground;

    return Scaffold(
      backgroundColor: screenBackground,
      body: SafeArea(
        bottom: false, // Allow indicator to extend to bottom
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 100.h),

              Text(
                'Welcome!\nSign up to continue!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge!.copyWith(
                  fontSize: 32.sp,
                  color: textColor,
                ),
              ),

              SizedBox(height: 70.h),

              
              AuthSocialButton(
                text: 'Sign Up with Google',
                iconAsset: AppAssets.googleIcon,
                onPressed: () {},
              ),
              SizedBox(height: 20.05.h),

              AuthSocialButton(
                text: 'Sign Up with Facebook',
                iconAsset: AppAssets.facebookIcon,
                onPressed: () {},
              ),

              SizedBox(height: 11.5.h),

              
              Center(
                child: Text(
                  'or',
                  style: TextStyle(color: AppColors.grey500, fontSize: 14.sp),
                ),
              ),

              SizedBox(height: 28.h),

              // Sign Up with Email Button (Helper Function)
              _buildPrimaryMethodButton(context, 'Sign up with email', () {
                context.go(
                  '/signup/details',
                ); // Navigate to the detailed sign up form
              }),

              SizedBox(height: 10.h),

              //Terms Footnote
              Text(
                'By signing up you are agreed with our friendly terms and condition.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey500, fontSize: 12.sp),
              ),

              SizedBox(height: 91.h),

              //Already have an account? Sign In Link
              Text(
                'Already have an account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 17.28.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: 10.h),

              // Sign In ButtonWhite button with blue text, matching Figma
              SizedBox(
                width: double.infinity,
                height: 60.h,
                child: ElevatedButton(
                  onPressed: () {
                    //context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Sign in',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 17.28.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
      // Home Indicator at the bottom
      bottomNavigationBar: HomeIndicator(
        color: AppColors.primary,
        backgroundColor: screenBackground,
        containerHeight: 34.h,
        height: 5.h,
        bottomPadding: 8.h,
      ),
    );
  }
}

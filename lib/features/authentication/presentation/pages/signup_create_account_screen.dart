// lib/features/authentication/presentation/screens/signup_create_account_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/authentication/presentation/widgets/auth_terms_checkbox.dart';
import 'package:nts_psc_app/features/authentication/presentation/widgets/auth_title_subtitle.dart';

class SignupCreateAccountScreen extends StatelessWidget {
  const SignupCreateAccountScreen({super.key});

  //  Helper Functions for Text Fields to wrap CustomTextFormField

  Widget _buildEmailField() {
    return const CustomTextFormField(
      hintText: 'Email id',
      prefixIcon: Icons.mail_outline_rounded,
      fillColor: AppColors.background, // Explicitly white background
      borderColor: Colors.transparent,
    );
  }

  Widget _buildPasswordField() {
    return const CustomTextFormField(
      hintText: 'Password',
      prefixIcon: Icons.lock_outlined,
      isPassword: true,
      fillColor: AppColors.background,
      borderColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = AppColors.primary;
    final Color bodyTextColor = AppColors.onBackground;

    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceVariant, // Light gray-blue background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 120.h),

              // icon
              Icon(Icons.people_alt, size: 60.sp, color: primaryColor),

              // reusable Title and Subtitle Block
              AuthTitleSubtitle(
                title: 'Create an Account',
                subtitle: 'A handful of model sentence structures',
                topPadding: 24.0,
              ),

              //input Fields
              _buildEmailField(),
              SizedBox(height: 16.h),
              _buildPasswordField(),
              SizedBox(height: 24.h),

              //reusable Terms Checkbox
              const AuthTermsCheckbox(),
              SizedBox(height: 32.h),

              //Create Account Button
              CustomButton(
                text: 'Create Account',
                onPressed: () {
                  // Navigation to success screen or next signup step
                },
                height: 56.h,
              ),
              SizedBox(height: 16.h),

              // 5. Existing Account Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: AppTextStyles.dmSans500med12.copyWith(
                      color: AppColors.grey500,
                      fontSize: 14.sp,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      //context.go('/login');
                    },
                    child: Text(
                      'Sign in',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
